/*************************************************************************************************

Welcome to Baml! To use this generated code, please run one of the following:

$ npm install @boundaryml/baml
$ yarn add @boundaryml/baml
$ pnpm add @boundaryml/baml

*************************************************************************************************/

// This file was generated by BAML: do not edit it. Instead, edit the BAML
// files and re-generate this code.
//
/* eslint-disable */
// tslint:disable
// @ts-nocheck
// biome-ignore format: autogenerated code
import type { BamlRuntime, BamlCtxManager, ClientRegistry, Image, Audio, Collector } from "@boundaryml/baml"
import { toBamlError } from "@boundaryml/baml"
import type { Checked, Check } from "./types"
import type { partial_types } from "./partial_types"
import type * as types from "./types"
import type {Dialogue, DialogueTurn, EventSourceType, EvidencePointer, EvidenceReference, KeyMoment, ModalityEvent, PatientImageTurn, SessionAnalysis, SessionTheme, SpeakerType, TherapeuticObservation, TurnSpecificVisualEvents, TurnSpecificVisualObservations, VisualObservation} from "./types"
import type TypeBuilder from "./type_builder"

export class LlmResponseParser {
  constructor(private runtime: BamlRuntime, private ctxManager: BamlCtxManager) {}

  
  AnalyzeSessionMultimodal(
      llmResponse: string,
      __baml_options__?: { tb?: TypeBuilder, clientRegistry?: ClientRegistry }
  ): SessionAnalysis {
    try {
      return this.runtime.parseLlmResponse(
        "AnalyzeSessionMultimodal",
        llmResponse,
        false,
        this.ctxManager.cloneContext(),
        __baml_options__?.tb?.__tb(),
        __baml_options__?.clientRegistry,
      ) as SessionAnalysis
    } catch (error) {
      throw toBamlError(error);
    }
  }
  
  AnalyzeVisualInput(
      llmResponse: string,
      __baml_options__?: { tb?: TypeBuilder, clientRegistry?: ClientRegistry }
  ): TurnSpecificVisualEvents[] {
    try {
      return this.runtime.parseLlmResponse(
        "AnalyzeVisualInput",
        llmResponse,
        false,
        this.ctxManager.cloneContext(),
        __baml_options__?.tb?.__tb(),
        __baml_options__?.clientRegistry,
      ) as TurnSpecificVisualEvents[]
    } catch (error) {
      throw toBamlError(error);
    }
  }
  
  SynthesizeTherapySession(
      llmResponse: string,
      __baml_options__?: { tb?: TypeBuilder, clientRegistry?: ClientRegistry }
  ): Dialogue {
    try {
      return this.runtime.parseLlmResponse(
        "SynthesizeTherapySession",
        llmResponse,
        false,
        this.ctxManager.cloneContext(),
        __baml_options__?.tb?.__tb(),
        __baml_options__?.clientRegistry,
      ) as Dialogue
    } catch (error) {
      throw toBamlError(error);
    }
  }
  
  SynthesizeVisualEvents(
      llmResponse: string,
      __baml_options__?: { tb?: TypeBuilder, clientRegistry?: ClientRegistry }
  ): TurnSpecificVisualObservations[] {
    try {
      return this.runtime.parseLlmResponse(
        "SynthesizeVisualEvents",
        llmResponse,
        false,
        this.ctxManager.cloneContext(),
        __baml_options__?.tb?.__tb(),
        __baml_options__?.clientRegistry,
      ) as TurnSpecificVisualObservations[]
    } catch (error) {
      throw toBamlError(error);
    }
  }
  
}

export class LlmStreamParser {
  constructor(private runtime: BamlRuntime, private ctxManager: BamlCtxManager) {}

  
  AnalyzeSessionMultimodal(
      llmResponse: string,
      __baml_options__?: { tb?: TypeBuilder, clientRegistry?: ClientRegistry }
  ): partial_types.SessionAnalysis {
    try {
      return this.runtime.parseLlmResponse(
        "AnalyzeSessionMultimodal",
        llmResponse,
        true,
        this.ctxManager.cloneContext(),
        __baml_options__?.tb?.__tb(),
        __baml_options__?.clientRegistry,
      ) as partial_types.SessionAnalysis
    } catch (error) {
      throw toBamlError(error);
    }
  }
  
  AnalyzeVisualInput(
      llmResponse: string,
      __baml_options__?: { tb?: TypeBuilder, clientRegistry?: ClientRegistry }
  ): (partial_types.TurnSpecificVisualEvents | null)[] {
    try {
      return this.runtime.parseLlmResponse(
        "AnalyzeVisualInput",
        llmResponse,
        true,
        this.ctxManager.cloneContext(),
        __baml_options__?.tb?.__tb(),
        __baml_options__?.clientRegistry,
      ) as (partial_types.TurnSpecificVisualEvents | null)[]
    } catch (error) {
      throw toBamlError(error);
    }
  }
  
  SynthesizeTherapySession(
      llmResponse: string,
      __baml_options__?: { tb?: TypeBuilder, clientRegistry?: ClientRegistry }
  ): partial_types.Dialogue {
    try {
      return this.runtime.parseLlmResponse(
        "SynthesizeTherapySession",
        llmResponse,
        true,
        this.ctxManager.cloneContext(),
        __baml_options__?.tb?.__tb(),
        __baml_options__?.clientRegistry,
      ) as partial_types.Dialogue
    } catch (error) {
      throw toBamlError(error);
    }
  }
  
  SynthesizeVisualEvents(
      llmResponse: string,
      __baml_options__?: { tb?: TypeBuilder, clientRegistry?: ClientRegistry }
  ): (partial_types.TurnSpecificVisualObservations | null)[] {
    try {
      return this.runtime.parseLlmResponse(
        "SynthesizeVisualEvents",
        llmResponse,
        true,
        this.ctxManager.cloneContext(),
        __baml_options__?.tb?.__tb(),
        __baml_options__?.clientRegistry,
      ) as (partial_types.TurnSpecificVisualObservations | null)[]
    } catch (error) {
      throw toBamlError(error);
    }
  }
  
}