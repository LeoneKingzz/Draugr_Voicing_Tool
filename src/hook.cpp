#include "hook.h"
#include "ClibUtil/editorID.hpp"

namespace hooks
{
    RE::TESForm;
    void on_animation_event::GetEquippedShout(RE::Actor *actor, bool SpellFire){
        auto limboshout = actor->GetActorRuntimeData().selectedPower;

        if (limboshout && limboshout->Is(RE::FormType::Shout)){
            auto data = RE::TESDataHandler::GetSingleton();
            auto Hen = limboshout->As<RE::TESShout>()->variations->spell->GetKeywords();

            for (RE::BGSKeyword* Yen : Hen){
                std::string Lsht = (clib_util::editorID::get_editorID(Yen));
                switch (hash(Lsht.c_str(), Lsht.size())){
                case "DSV_UnrelentingForce"_h:
                    if (SpellFire){
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x802, "DraugrShoutVoicing.esp")));
                    }else{
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x800, "DraugrShoutVoicing.esp")));
                    }
                    break;

                case "DSV_Dismay"_h:
                    if (SpellFire){
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x805, "DraugrShoutVoicing.esp")));
                    }else{
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x804, "DraugrShoutVoicing.esp")));
                    }
                    break;

                case "DSV_IceForm"_h:
                    if (SpellFire){
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x807, "DraugrShoutVoicing.esp")));
                    }else{
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x806, "DraugrShoutVoicing.esp")));
                    }
                    break;

                case "DSV_Disarm"_h:
                    if (SpellFire){
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x809, "DraugrShoutVoicing.esp")));
                    }else{
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x808, "DraugrShoutVoicing.esp")));
                    }
                    break;

                case "DSV_FrostBreath"_h:
                    if (SpellFire){
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x80B, "DraugrShoutVoicing.esp")));
                    }else{
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x80A, "DraugrShoutVoicing.esp")));
                    }
                    break;

                case "DSV_PhantomForm"_h:
                    if (SpellFire){
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x80D, "DraugrShoutVoicing.esp")));
                    }else{
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x80C, "DraugrShoutVoicing.esp")));
                    }
                    break;

                case "DSV_ElementalFury"_h:
                    if (SpellFire){
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x80F, "DraugrShoutVoicing.esp")));
                    }else{
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x80E, "DraugrShoutVoicing.esp")));
                    }
                    break;

                case "DSV_BecomeEthereal"_h:
                    if (SpellFire){
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x811, "DraugrShoutVoicing.esp")));
                    }else{
                        util::playSound(actor, (data->LookupForm<RE::BGSSoundDescriptorForm>(0x810, "DraugrShoutVoicing.esp")));
                    }
                    break;

                default:

                    break;
                }
            }
        }
    }


	void on_animation_event::ProcessEvent(RE::BSTEventSink<RE::BSAnimationGraphEvent>* a_sink, RE::BSAnimationGraphEvent* a_event, RE::BSTEventSource<RE::BSAnimationGraphEvent>* a_eventSource)
	{
		if (!a_event->holder) {
			return;
		}
		//std::string_view eventTag = a_event->tag.data();
		RE::Actor* actor = const_cast<RE::TESObjectREFR*>(a_event->holder)->As<RE::Actor>();
        auto data = RE::TESDataHandler::GetSingleton();
        if(actor->GetActorBase()->GetVoiceType() == data->LookupForm<RE::BGSVoiceType>(0x1F1CD, "Skyrim.esm")){
            switch (hash(a_event->tag.c_str(), a_event->tag.size())){
            case "BeginCastVoice"_h:

                GetEquippedShout(actor);

                break;

            case "Voice_SpellFire_Event"_h:

                GetEquippedShout(actor, true);

                break;
            }
        }
        
	}

	EventResult on_animation_event::ProcessEvent_NPC(RE::BSTEventSink<RE::BSAnimationGraphEvent>* a_sink, RE::BSAnimationGraphEvent* a_event, RE::BSTEventSource<RE::BSAnimationGraphEvent>* a_eventSource)
	{
		ProcessEvent(a_sink, a_event, a_eventSource);
		return _ProcessEvent_NPC(a_sink, a_event, a_eventSource);
	}

}