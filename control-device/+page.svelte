<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import CustomTerminal from '$lib/components/ui/custom-terminal/custom-terminal.svelte';

	import {
		connectSignalR,
		handleStreamConnected,
		cleanup,
		controlChannel
	} from './(common)/p2pService';
	import type { ControlType } from './(common)/types';
	import ControlScreen from './(common)/controlScreen.svelte';
	import NavigationPanel from './(common)/navigationPanel.svelte';

	let showTerminal = $state(true);

	let deviceId = $state('');
	let errorMessage = $state('');

	let videoRef = $state<HTMLVideoElement | null>(null);

	let screenWidth = $state<number>(1080);
	let screenHeight = $state<number>(2220);
	let windowWidth = $state<number>(0);
	let windowHeight = $state<number>(0);

	let terminalComponent = $state<CustomTerminal | null>(null);

	let lastY = $state<number>(0);

	// Derived values for responsive UI
	let aspectRatio = $derived<number>(screenWidth / screenHeight);
	let idealVideoHeight = $derived<number>(windowHeight);
	let idealVideoWidth = $derived<number>(idealVideoHeight * aspectRatio);

	// Final video dimensions that maintain aspect ratio
	let videoWidth = $derived<number>(idealVideoWidth);
	let videoHeight = $derived<number>(idealVideoHeight);

	// Scale factor for mouse coordinates
	let scaleFactor = $derived<number>(videoWidth / screenWidth);

	// Prevent continuous resizing by adding a debounce and minimum threshold
	let lastResizeTime = $state<number>(0);
	let resizeDebounceMs = 500; // Minimum time between resize operations
	let resizeThreshold = 20; // Minimum pixel difference to trigger resize
	let windowNeedsResize = $derived<boolean>(
		Math.abs(windowWidth - idealVideoWidth) > resizeThreshold &&
			Date.now() - lastResizeTime > resizeDebounceMs
	);

	// Effect to resize window when needed with debounce
	$effect(() => {
		if (windowNeedsResize && typeof window !== 'undefined') {
			lastResizeTime = Date.now();
			window.resizeTo(idealVideoWidth, windowHeight);

			// Update window dimensions after resize
			setTimeout(() => {
				windowWidth = window.innerWidth;
				windowHeight = window.innerHeight;
			}, 200);
		}
	});

	async function onSendControl(controlType: ControlType, params: Record<string, any> = {}) {
		try {
			if (!controlChannel || controlChannel.readyState !== 'open') {
				console.error('Control channel not ready');
				return false;
			}
			const message = {
				type: controlType,
				...params
			};
			controlChannel.send(JSON.stringify(message));
			return true;
		} catch (error) {
			console.error('Error sending control command:', error);
			return false;
		}
	}

	onMount(async () => {
		windowWidth = window.innerWidth;
		windowHeight = window.innerHeight;

		const url = new URL(window.location.href);
		deviceId = url.searchParams.get('deviceId') || '';

		if (!deviceId) {
			errorMessage = 'Device ID not found in URL parameters';
			return;
		}

		let resizeTimeout: number;
		const handleResize = () => {
			clearTimeout(resizeTimeout);
			resizeTimeout = window.setTimeout(() => {
				windowWidth = window.innerWidth;
				windowHeight = window.innerHeight;
			}, 200);
		};

		window.addEventListener('resize', handleResize);

		await connectSignalR(
			deviceId,
			terminalComponent,
			showTerminal,
			(width: number, height: number) => {
				screenWidth = width;
				screenHeight = height;
			},
			(stream: MediaStream) => {
				console.log('Track received in component callback', stream);
				if (videoRef) {
					videoRef.srcObject = stream;
				}

				handleStreamConnected(terminalComponent, showTerminal, (value) => {
					showTerminal = value;
				}).catch((err) => {
					console.error('Error handling stream connection:', err);
				});
			}
		);
	});

	onDestroy(() => {
		cleanup();
	});
</script>

<div class="fixed inset-0 m-0 overflow-hidden bg-black p-0">
	{#if showTerminal}
		<div class="absolute inset-0 z-20">
			<CustomTerminal class="h-full w-full" bind:this={terminalComponent} />
		</div>
	{/if}

	<div
		class="absolute inset-0 {showTerminal ? 'hidden' : 'block'} m-0 overflow-hidden bg-black p-0"
	>
		<div class="m-0 flex h-full w-full items-center justify-center p-0">
			<div
				class="relative m-0 p-0"
				style="height: {videoHeight}px; width: {videoWidth}px; max-width: 100vw; overflow: hidden;"
			>
				<video
					bind:this={videoRef}
					autoPlay
					muted
					playsInline
					class="m-0 h-full w-full border-none object-cover p-0"
					style="
						will-change: transform; 
						transform: translateZ(0); 
						backface-visibility: hidden; 
						image-rendering: auto;
					"
					id="remoteVideo"
				></video>
				<ControlScreen {onSendControl} {scaleFactor} />
			</div>
		</div>
		<NavigationPanel {onSendControl} />
	</div>
</div>
