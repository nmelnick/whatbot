import { factory } from '../Logger';
import { Command, RegexCommand, MonitorCommand } from '../Command';
import { Message } from '../Message';

const log = factory.getLogger('Awareness');

const reGreeted = /^(hey|hi|hello|word|sup|morning|good morning)[\?\!\. ]*?$/i;
const greetings = [
    'hey',
    'sup',
    "what's up",
    'yo',
    'word',
    'hi',
    'hello',
    'greetings',
    'allo'
];

/**
 * This is basic, just responds to greetings to it's own name.
 */
export class Awareness extends Command {
    requireDirect = false;
    lastMessage?: Message = null;
    
    @MonitorCommand()
    async message(message?: Message): Promise<string> {
        this.lastMessage = message;

        // Self-awareness
        const me = message.me;
        const reMe = new RegExp('^' + me + '[\?\!\.]?$/', 'i');
        if (reMe.test(message.content)) {
            return 'what';
        }
        
        // Greeted
        if (message.isToWhatbot && reGreeted.test(message.content)) {
            return greetings[Math.floor(Math.random() * greetings.length)] + ', ' + this.tagUser(message.sender) + '.';
        }
    }

    @RegexCommand(/^show last message/i)
    async showLastMessage(message?: Message): Promise<Message> {
        return this.lastMessage;
    }
}
