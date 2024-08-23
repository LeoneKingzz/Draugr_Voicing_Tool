#include "SKSE/Trampoline.h"
#include "util.h"
#pragma warning(disable: 4100)


namespace hooks
{

	using EventResult = RE::BSEventNotifyControl;

	class on_animation_event
	{
	public:
		static void install()
		{
			REL::Relocation<uintptr_t> AnimEventVtbl_NPC{ RE::VTABLE_Character[2] };
			//REL::Relocation<uintptr_t> AnimEventVtbl_PC{ RE::VTABLE_PlayerCharacter[2] };

			_ProcessEvent_NPC = AnimEventVtbl_NPC.write_vfunc(0x1, ProcessEvent_NPC);
			//_ProcessEvent_PC = AnimEventVtbl_PC.write_vfunc(0x1, ProcessEvent_PC);
			logger::info("hook:on_animation_event");
		}
        static void GetEquippedShout(RE::Actor *actor, bool SpellFire = false);

    private:
		static inline void ProcessEvent(RE::BSTEventSink<RE::BSAnimationGraphEvent>* a_sink, RE::BSAnimationGraphEvent* a_event, RE::BSTEventSource<RE::BSAnimationGraphEvent>* a_eventSource);

		static EventResult ProcessEvent_NPC(RE::BSTEventSink<RE::BSAnimationGraphEvent>* a_sink, RE::BSAnimationGraphEvent* a_event, RE::BSTEventSource<RE::BSAnimationGraphEvent>* a_eventSource);
		//static EventResult ProcessEvent_PC(RE::BSTEventSink<RE::BSAnimationGraphEvent>* a_sink, RE::BSAnimationGraphEvent* a_event, RE::BSTEventSource<RE::BSAnimationGraphEvent>* a_eventSource);

		static inline REL::Relocation<decltype(ProcessEvent_NPC)> _ProcessEvent_NPC;
		//static inline REL::Relocation<decltype(ProcessEvent_NPC)> _ProcessEvent_PC;
    };
	

	inline void alloc() 
	{
		SKSE::AllocTrampoline(1 << 8);
	}

	class util
	{
	private:
		static int soundHelper_a(void *manager, RE::BSSoundHandle *a2, int a3, int a4) // sub_140BEEE70
		{
			using func_t = decltype(&soundHelper_a);
			REL::Relocation<func_t> func{RELOCATION_ID(66401, 67663)};
			return func(manager, a2, a3, a4);
		}

		static void soundHelper_b(RE::BSSoundHandle *a1, RE::NiAVObject *source_node) // sub_140BEDB10
		{
			using func_t = decltype(&soundHelper_b);
			REL::Relocation<func_t> func{RELOCATION_ID(66375, 67636)};
			return func(a1, source_node);
		}

		static char __fastcall soundHelper_c(RE::BSSoundHandle *a1) // sub_140BED530
		{
			using func_t = decltype(&soundHelper_c);
			REL::Relocation<func_t> func{RELOCATION_ID(66355, 67616)};
			return func(a1);
		}

		static char set_sound_position(RE::BSSoundHandle *a1, float x, float y, float z)
		{
			using func_t = decltype(&set_sound_position);
			REL::Relocation<func_t> func{RELOCATION_ID(66370, 67631)};
			return func(a1, x, y, z);
		}

	public:
		static void playSound(RE::Actor *a, RE::BGSSoundDescriptorForm *a_descriptor)
		{
			//logger::info("starting voicing....");

			RE::BSSoundHandle handle;
			handle.soundID = static_cast<uint32_t>(-1);
			handle.assumeSuccess = false;
			*(uint32_t *)&handle.state = 0;

			soundHelper_a(RE::BSAudioManager::GetSingleton(), &handle, a_descriptor->GetFormID(), 16);

			if (set_sound_position(&handle, a->data.location.x, a->data.location.y, a->data.location.z))
			{
				soundHelper_b(&handle, a->Get3D());
				soundHelper_c(&handle);
				//logger::info("FormID {}"sv, a_descriptor->GetFormID());
				//logger::info("voicing complete");
			}
		}

		static RE::BGSSoundDescriptor *GetSoundRecord(const char* description)
		{

			auto Ygr = RE::TESForm::LookupByEditorID<RE::BGSSoundDescriptor>(description);

			return Ygr;
		}
	};
};

// auto a = RE::TESForm::LookupByEditorID<RE::BGSSoundDescriptorForm>("aaaUDDragonAISpell");
