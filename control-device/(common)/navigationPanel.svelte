<script lang="ts">
	import Home from 'lucide-svelte/icons/home';
	import ArrowLeft from 'lucide-svelte/icons/arrow-left';
	import Apps from 'lucide-svelte/icons/layout-grid';
	import { ControlType } from './types';

	let {
		onSendControl,
	} = $props<{
		onSendControl: (controlType: ControlType, params: Record<string, any>) => void;
	}>();

</script>

<div class="absolute right-0 top-0 bottom-0 w-[50px] flex flex-col justify-end z-20 pointer-events-none">
	<div class="flex flex-col gap-3 py-2.5 mb-[30px] pointer-events-auto">
		<button 
			class="flex items-center justify-center w-10 h-10 rounded-full bg-[rgba(30,30,30,0.8)] text-white border-none cursor-pointer mx-auto transition-all duration-200 shadow-md hover:bg-[rgba(60,60,60,0.9)] hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow" 
			onclick={() => onSendControl(ControlType.BACK)}
			title="Back"
		>
			<ArrowLeft class="h-5 w-5" />
		</button>
		<button 
			class="flex items-center justify-center w-10 h-10 rounded-full bg-[rgba(30,30,30,0.8)] text-white border-none cursor-pointer mx-auto transition-all duration-200 shadow-md hover:bg-[rgba(60,60,60,0.9)] hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow" 
			onclick={() => onSendControl(ControlType.HOME)}
			title="Home"
		>
			<Home class="h-5 w-5" />
		</button>
		<button 
			class="flex items-center justify-center w-10 h-10 rounded-full bg-[rgba(30,30,30,0.8)] text-white border-none cursor-pointer mx-auto transition-all duration-200 shadow-md hover:bg-[rgba(60,60,60,0.9)] hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow" 
			onclick={() => onSendControl(ControlType.RECENT)}
			title="Recent Apps"
		>
			<Apps class="h-5 w-5" />
		</button>
	</div>
</div>
