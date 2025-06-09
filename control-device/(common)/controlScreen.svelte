<script lang="ts">
	import { onDestroy, onMount } from 'svelte';
	import { ControlType, restrictedKeys, specialKeyMappings } from './types';
	
    let {
		onSendControl,
        scaleFactor,
	} = $props<{
		onSendControl: (controlType: ControlType, params: Record<string, any>) => void;
        scaleFactor?: number;
	}>();

	let isFocused = $state(false);
	
	let isMouseDown = $state<boolean>(false);
	let lastX = $state<number>(0);
	let lastY = $state<number>(0);

	function getCoordinates(
		event: MouseEvent | TouchEvent,
		element: HTMLElement,
		scaleFactor: number,
		lastX: number,
		lastY: number
	) {
		const rect = element.getBoundingClientRect();
		let clientX, clientY;

		if ('touches' in event) {
			if (event.touches.length === 0) {
				return { x: lastX, y: lastY };
			}
			clientX = event.touches[0].clientX;
			clientY = event.touches[0].clientY;
		} else {
			clientX = event.clientX;
			clientY = event.clientY;
		}

		const x = (clientX - rect.left) / scaleFactor;
		const y = (clientY - rect.top) / scaleFactor;

		return { x: Math.round(x), y: Math.round(y) };
	}

	

	 async function sendClipboardText() {
		try {
			const text = await navigator.clipboard.readText();
			if (text) {
				await onSendControl(ControlType.MOUSE_INPUT_TEXT, { msg: text });
				console.log('Clipboard text sent:', text);
			}
		} catch (error) {
			console.error('Failed to read clipboard:', error);
		}
	}

	 function sendKeyMessage(key: string) {
		if (restrictedKeys.includes(key)) {
			return;
		}
		const messageText = specialKeyMappings[key] || key;
		onSendControl(ControlType.MOUSE_INPUT_TEXT, { msg: messageText });
	}

	 function handleKeyDown(
		e: KeyboardEvent,
		isFocused: boolean,
	) {
		if (!isFocused) return;
		const key = e.key.toLowerCase();
		if (e.ctrlKey && key === 'v') {
			e.preventDefault();
			sendClipboardText();
		} else if (e.ctrlKey && key === 'c') {
			e.preventDefault();
			onSendControl(ControlType.MOUSE_INPUT_TEXT, { msg: '[CTRL_C]' });
		} else if (e.ctrlKey && key === 'a') {
			e.preventDefault();
			onSendControl(ControlType.MOUSE_INPUT_TEXT, { msg: '[CTRL_A]' });
		} else if (
			key === 'tab' ||
			key === 'arrowup' ||
			key === 'arrowdown' ||
			key === 'arrowleft' ||
			key === 'arrowright'
		) {
			e.preventDefault();
			sendKeyMessage(e.key);
		} else {
			sendKeyMessage(e.key);
		}
	}

	 function handleMouseDown(
		event: MouseEvent,
		isMouseDown: boolean,
		setIsMouseDown: (v: boolean) => void,
		scaleFactor: number,
		lastX: number,
		lastY: number
	) {
		const target = event.currentTarget as HTMLElement;
		if (event.button === 0) {
			event.preventDefault();
			setIsMouseDown(true);
			const { x, y } = getCoordinates(event, target, scaleFactor, lastX, lastY);
			onSendControl(ControlType.MOUSE_DOWN, { x, y });
		} else if (event.button === 2) {
			event.preventDefault();
			onSendControl(ControlType.BACK);
		} else if (event.button === 1) {
			event.preventDefault();
			onSendControl(ControlType.HOME);
		}
	}

	 function handleMouseMove(
		event: MouseEvent,
		isMouseDown: boolean,
		scaleFactor: number,
		lastX: number,
		lastY: number
	) {
		if (!isMouseDown) return;
		event.preventDefault();
		const target = event.currentTarget as HTMLElement;
		const { x, y } = getCoordinates(event, target, scaleFactor, lastX, lastY);
		onSendControl(ControlType.MOUSE_MOVE, { x, y });
	}

	 function handleMouseUp(
		event: MouseEvent,
		isMouseDown: boolean,
		setIsMouseDown: (v: boolean) => void,
		scaleFactor: number,
		lastX: number,
		lastY: number
	) {
		if (!isMouseDown) return;
		event.preventDefault();
		setIsMouseDown(false);
		const target = event.currentTarget as HTMLElement;
		const { x, y } = getCoordinates(event, target, scaleFactor, lastX, lastY);
		onSendControl(ControlType.MOUSE_UP, { x, y });
	}

	 function handleTouchStart(
		event: TouchEvent,
		setIsMouseDown: (v: boolean) => void,
		scaleFactor: number,
		lastX: number,
		lastY: number
	) {
		event.preventDefault();
		setIsMouseDown(true);
		const target = event.currentTarget as HTMLElement;
		const { x, y } = getCoordinates(event, target, scaleFactor, lastX, lastY);
		onSendControl(ControlType.MOUSE_DOWN, { x, y });
	}

	 function handleTouchMove(
		event: TouchEvent,
		isMouseDown: boolean,
		scaleFactor: number,
		lastX: number,
		lastY: number
	) {
		if (!isMouseDown) return;
		event.preventDefault();
		const target = event.currentTarget as HTMLElement;
		const { x, y } = getCoordinates(event, target, scaleFactor, lastX, lastY);
		onSendControl(ControlType.MOUSE_MOVE, { x, y });
	}

	 function handleTouchEnd(
		event: TouchEvent,
		isMouseDown: boolean,
		setIsMouseDown: (v: boolean) => void,
		scaleFactor: number,
		lastX: number,
		lastY: number
	) {
		if (!isMouseDown) return;
		event.preventDefault();
		setIsMouseDown(false);
		const target = event.currentTarget as HTMLElement;
		const { x, y } = getCoordinates(event, target, scaleFactor, lastX, lastY);
		onSendControl(ControlType.MOUSE_UP, { x, y });
	}

    function handleFocus() {
		isFocused = true;
	}
	function handleBlur() {
		isFocused = false;
	}

	function handleWindowKeyDown(e: KeyboardEvent) {
		handleKeyDown(e, isFocused);
	}


	onMount(() => {
        window.addEventListener('keydown', handleWindowKeyDown);
	});


    onDestroy(() => {
		window.removeEventListener('keydown', handleWindowKeyDown);
	
	});


</script>

<div
	class="absolute inset-0 z-10 cursor-default"
	role="button"
	tabindex="0"
	aria-label="Device control overlay"
	oncontextmenu={(e) => e.preventDefault()}
	onmousedown={(e) =>
		handleMouseDown(
			e,
			isMouseDown,
			(v) => (isMouseDown = v),
			scaleFactor,
			lastX,
			lastY
		)}
	onmousemove={(e) => handleMouseMove(e, isMouseDown, scaleFactor, lastX, lastY)}
	onmouseup={(e) =>
		handleMouseUp(
			e,
			isMouseDown,
			(v) => (isMouseDown = v),
			
			scaleFactor,
			lastX,
			lastY
		)}
	ontouchstart={(e) =>
		handleTouchStart(e, (v) => (isMouseDown = v), scaleFactor, lastX, lastY)}
	ontouchmove={(e) => handleTouchMove(e, isMouseDown, scaleFactor, lastX, lastY)}
	ontouchend={(e) =>
		handleTouchEnd(
			e,
			isMouseDown,
			(v) => (isMouseDown = v),
			scaleFactor,
			lastX,
			lastY
		)}
	onfocus={handleFocus}
	onblur={handleBlur}
	onclick={handleFocus}
	onkeydown={(e) => handleKeyDown(e, isFocused)}
></div>


 