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

/**
 * The RegexCommand decorator will fire if the given regex is found on any
 * input, whether the command name is involved or not. This is useful for
 * parsing any content in a message, or looking for a triggering keyword.
 */
export function RegexCommand(regex: RegExp) {
    return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
        State.addCommand(regex, target, propertyKey);
    };
}

/**
 * The MonitorCommand decorator will fire on any incoming, visible message.
 */
export function MonitorCommand() {
    return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
        State.addCommand(/./, target, propertyKey);
    };
}

/**
 * The EventCommand decorator will fire on room event types.  To specify
 * multiple events to respond to, multiple decorators must be provided. The
 * method called will be provided context, which is the context that the event
 * was fired from, and eventInfo, an EventInfo object containing event data.
 * Events are provided by Communicators, so you will want to check those for
 * additional event types. In general, the possible events are:
 * 
 * * enter : eventInfo contains 'nick'
 * * user_change : eventInfo contains 'nick', 'old_nick'
 * * leave : eventInfo contains 'nick'
 * * ping : eventInfo contains 'source'
 * * topic : eventInfo contains 'nick', 'topic'
 */
export function EventCommand() {
    return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
        State.addCommand(/./, target, propertyKey);
    };
}
