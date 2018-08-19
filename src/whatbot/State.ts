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
     * @param t RegExp or RoomEvent to trigger the method
     * @param c Class prototype
     * @param m Method name
     */
    export function addCommand(t: RegExp | RoomEvent, c: any, m: string) {
        log.debug('Adding command ' + t + ' => ' + c.constructor.name + '::' + m)
        if (t instanceof RegExp) {
            commands.push({ trigger: t, class: c, method: m });
        } else {
            commands.push({ event: t, class: c, method: m });
        }
    }
}

class CommandDefinition {
    trigger?: RegExp
    event?: RoomEvent
    class: any
    method: any
}

enum RoomEvent {
    Enter,
    UserChange,
    Leave,
    Topic,
    Ping
}