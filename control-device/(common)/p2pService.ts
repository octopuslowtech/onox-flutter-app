import { HttpTransportType, HubConnection, HubConnectionBuilder, LogLevel } from '@microsoft/signalr';
import { getCookie } from '$lib/utils/cookies';
import type CustomTerminal from '$lib/components/ui/custom-terminal/custom-terminal.svelte';

// Connection references
export let peerConnectionRef: RTCPeerConnection | null = null;
export let signalRConnectionRef: HubConnection | null = null;
export let controlChannel: RTCDataChannel | null = null;
export let fileChannel: RTCDataChannel | null = null;
export let errorConnect: string = '';



// Define an interface for the message structure
interface SignalRMessage {
  type?: string;
  deviceId?: string;
  data?: string;
  [key: string]: any;
}

export function parseIceData(iceArray: string[]): RTCIceServer[] {
  return iceArray
    .map((entry) => {
      const [url, port, username, credential] = entry.split('|');
      if (url && port) {
        const isTurn = url.toLowerCase().includes('turn');
        const finalUrl = isTurn ? `turn:${url}:${port}` : `${url}:${port}`;

        return {
          urls: finalUrl,
          username: username || undefined,
          credential: credential || undefined
        } as RTCIceServer;
      }
      return undefined;
    })
    .filter((server): server is RTCIceServer => server !== undefined);
}

export async function connectSignalR(
  deviceId: string,
  terminalComponent: CustomTerminal | null,
  showTerminal: boolean,
  onTransferInfo: (width: number, height: number) => void,
  onTrack?: (stream: MediaStream) => void
) {
  errorConnect = '';
  
  if (showTerminal && terminalComponent) {
    await terminalComponent.clearActions();
  }
  
  const urlHub = 'https://socket.maxcloudphone.com/deviceRHub?type=client';
  const token = getCookie('access_token') || '';

  try {
    if (showTerminal && terminalComponent) {
      await terminalComponent.addAction('Building SignalR connection with authentication');
    }
    
    signalRConnectionRef = new HubConnectionBuilder()
      .withUrl(urlHub, {
        accessTokenFactory: () => token,
        transport: HttpTransportType.WebSockets,
      skipNegotiation: true,
      })
      .withAutomaticReconnect()
      .configureLogging(LogLevel.Information)
      .build();

    if (showTerminal && terminalComponent) {
      await terminalComponent.addAction('Registering message handler for device events');
    }
    
    signalRConnectionRef.on('MESSAGE', async (message: SignalRMessage | string) => {
      let messageJson: { type: string; deviceId: string; data?: string };

      if (typeof message === 'string') {
        try {
          messageJson = JSON.parse(message);
        } catch (error) {
          console.error('Error parsing message:', error);
          return;
        }
      } else if (typeof message === 'object' && message !== null) {
        messageJson = message;
      } else {
        console.error('Received message is neither string nor object:', message);
        return;
      }

      const type = messageJson.type;
      // const messageDeviceId = messageJson.deviceId;

      if (type === 'DEVICE_CONNECTED') {
        // Handle device connected
      }

      if (type === 'DEVICE_DISCONNECTED') {
        // Handle device disconnected
      }

      if (type === 'TRANSFER_INFO') {
        const dataStr = messageJson.data;
        if (!dataStr) return;

        const { width, height } = JSON.parse(dataStr);
        onTransferInfo(width, height);
      }

      if (type === 'TRANSFER_SDP') {
        const dataStr = messageJson.data;
        if (!dataStr) return;

        const dataJson = JSON.parse(dataStr);
        if (dataJson.type === 'offer') {
          try {
            await createPeer(dataJson.ice, deviceId, onTrack);
            await peerConnectionRef!.setRemoteDescription(new RTCSessionDescription(dataJson));
            const answer = await peerConnectionRef!.createAnswer();
            await peerConnectionRef!.setLocalDescription(answer);
            await signalRConnectionRef!.invoke(
              'SendToDevice',
              deviceId,
              'TRANSFER_SDP',
              JSON.stringify({
                type: 'answer',
                sdp: answer.sdp
              })
            );
          } catch (e) {
            console.error('Error handling received offer', e);
          }
        }
        if (dataJson.type === 'candidate') {
          const candidate = new RTCIceCandidate({
            sdpMid: dataJson.sdpMid,
            candidate: dataJson.candidate
          });
          try {
            await peerConnectionRef!.addIceCandidate(candidate);
          } catch (e) {
            console.error(candidate, 'Error adding received ICE candidate' + e);
          }
        }
      }
    });

    await signalRConnectionRef.start();
    await signalRConnectionRef.invoke('AddDeviceToGroup', [deviceId]);
    await addActionToTerminal(terminalComponent, 'Connection established successfully');
  } catch (error) {
    console.error('SignalR connection error:', error);
    errorConnect = 'Failed to connect: ' + (error instanceof Error ? error.message : String(error));
    await addActionToTerminal(terminalComponent, 'Connection error: ' + errorConnect);
  }
}

export async function createPeer(
  iceServers: string[],
  deviceId: string,
  onTrack?: (stream: MediaStream) => void,
) {
  console.log('Creating peer connection with ice servers:', iceServers);
  const parsedIceServers = parseIceData(iceServers);
  
  peerConnectionRef = new RTCPeerConnection({
    iceServers: parsedIceServers
  });
  
  console.log('Peer connection created:', peerConnectionRef);
  
  peerConnectionRef.onicecandidate = (event) => {
    if (event.candidate) {
      console.log('ICE candidate found:', event.candidate);
      signalRConnectionRef?.invoke(
        'SendToDevice',
        deviceId,
        'TRANSFER_SDP',
        JSON.stringify({
            type: "candidate",
            sdpMid: event.candidate.sdpMid,
            sdpMLineIndex: event.candidate.sdpMLineIndex,
            candidate: event.candidate.candidate,
          })
      );
    }
  };
  
  peerConnectionRef.ontrack = (event) => {
    if (event.streams && event.streams[0]) {
        onTrack?.(event.streams[0]);
      } 
  };

  peerConnectionRef.ondatachannel = async (event) => {
    console.log('Data channel received:', event.channel.label);
    const channel = event.channel;

    if (channel.label === 'controlChanel') {
      controlChannel = channel;
      channel.onmessage = (event) => {
        console.log(event.data, 'controlChannel');
      };
    }
    if (channel.label === 'fileChannel') {
      fileChannel = channel;
      channel.onmessage = (event) => {
        console.log(event.data, 'fileChannel');
      };
    }
  };
  
  // Log connection state changes
  peerConnectionRef.onconnectionstatechange = () => {
    console.log('Connection state changed:', peerConnectionRef?.connectionState);
  };
  
  peerConnectionRef.onsignalingstatechange = () => {
    console.log('Signaling state changed:', peerConnectionRef?.signalingState);
  };
  
  peerConnectionRef.onicegatheringstatechange = () => {
    console.log('ICE gathering state changed:', peerConnectionRef?.iceGatheringState);
  };
  
  peerConnectionRef.oniceconnectionstatechange = () => {
    console.log('ICE connection state changed:', peerConnectionRef?.iceConnectionState);
  };
}

export async function addActionToTerminal(terminalComponent: CustomTerminal | null, text: string) {
  if (terminalComponent) {
    await terminalComponent.addAction(text);
  }
}

export async function handleStreamConnected(
  terminalComponent: CustomTerminal | null,
  showTerminal: boolean,
  setShowTerminal: (value: boolean) => void
) {
  if (terminalComponent && showTerminal) {
    try {
      await addActionToTerminal(terminalComponent, 'Connect Success');
      setTimeout(() => {
        setShowTerminal(false);
      }, 2000);
    } catch (error) {
      console.error('Error handling stream connection:', error);
    }
  }
}

export function cleanup() {
  if (signalRConnectionRef) {
    signalRConnectionRef.stop();
  }
  if (peerConnectionRef) {
    peerConnectionRef.close();
  }
} 