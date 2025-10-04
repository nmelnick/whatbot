/**
 * State.js - Singleton to track global state
 * Matches Whatbot::State from Perl version
 */

class State {
  static #instance = null;

  constructor(config) {
    if (State.#instance) {
      throw new Error('State is a singleton. Use State.instance()');
    }
    
    this.parent = null;
    this.config = null;
    this.ios = {};
    this.database = null;
    this.log = null;
    this.controller = null;
    this.models = {};
  }

  static initialize({ parent, config, log }) {
    State.#instance = new State();
    State.#instance.parent = parent;
    State.#instance.config = config;
    State.#instance.log = log;
    return State.#instance;
  }

  static instance() {
    if (!State.#instance) {
      throw new Error('State not initialized. Call State.initialize() first.');
    }
    return State.#instance;
  }

  static reset() {
    State.#instance = null;
  }
}

export default State;
