import { factory } from './Logger';
import { Communicator } from './Communicator';

const log = factory.getLogger('State');

export namespace State {
    export let commands: Array<CommandDefinition> = [];

    /**
     * Resolve a Communicator instance by context
     * @param context Context identifier
     */
    export function resolveCommunicator(context: string): Communicator {
        return null;
    }

    /**
     * Add a Command instance to the pool.
     * @param t RegExp to trigger the method
     * @param c Class prototype
     * @param m Method name
     */
    export function addCommand(t: RegExp, c: any, m: string) {
        log.debug('Adding command ' + t + ' => ' + c.constructor.name + '::' + m)
        commands.push({ trigger: t, class: c, method: m });
    }
}

class CommandDefinition {
    trigger: RegExp
    class: any
    method: any
}