import { factory } from './Logger';
import { Message } from './Message';
import { State } from './State';

const log = factory.getLogger('Command');

export interface Command {
    requireDirect: boolean
}

/**
 * The SimpleCommand decorator is the most basic event type. The given method
 * would fire when a message comes in with "<command-name> <method-name>". For
 * example, for the command "Seen", and the method name "test", then it would
 * fire if someone stated "seen test" in whatever context whatbot is listening.
 */
export function SimpleCommand() {
    return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
        const trigger = new RegExp('^' + target.constructor.name.toLowerCase() + ' +' + propertyKey, 'i');
        State.addCommand(trigger, target, propertyKey);
    };
}
