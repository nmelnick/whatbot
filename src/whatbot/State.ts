import { factory } from './Logger';
import { Communicator } from './Communicator';
import { Config } from './Config';

const log = factory.getLogger('State');

/**
 * Track state of the application.
 */
export class State {
    /** Whatbot configuration */
    static config = new Config();

    /** Loaded command paths */
    static commands: Array<CommandDefinition> = [];

    /**
     * Resolve a Communicator instance by context
     * @param context Context identifier
     */
    static resolveCommunicator(context: string): Communicator {
        log.debug('Resolving communicator "' + context +'"');
        return null;
    }

    /**
     * Add a Command instance to the pool.
     * @param t RegExp or RoomEvent to trigger the method
     * @param c Class prototype
     * @param m Method name
     */
    static addCommand(t: RegExp | RoomEvent, c: any, m: string): void {
        log.debug('Adding command ' + t + ' => ' + c.constructor.name + '::' + m)
        if (t instanceof RegExp) {
            this.commands.push({ trigger: t, class: c, method: m });
        } else {
            this.commands.push({ event: t, class: c, method: m });
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
