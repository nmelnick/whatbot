import { factory } from './Logger';
import { State } from './State';

const log = factory.getLogger('Message');

/**
 * Container class for incoming and outgoing messages. Each whatbot component,
 * when sending or receiving a message via a Communicator will pass these
 * objects, and messages sent through a Command is encouraged to use these
 * objects.
 */
export class Message {
    private _content: string

    /** User or entity the message is from */
    sender: string;

    /** User or entity the message is to */
    recipient: string;

    /** "Me" according to the communicator this message came from */
    get me(): string {
        return State.resolveCommunicator(this.context).me;
    }

    /** The text body of the message, which may contain tags as {!tag=value}. */
    get content(): string {
        return this._content;
    }

    set content(newContent: string) {
        const me = this.me;
        const options = [
            ', ?' + me + '[\?\!\. ]*?$',
            '^' + me + '[\:\,\- ]+'
        ];
        for (let i = 0; i < options.length; i++) {
            const re = new RegExp(options[i]);
            if (re.test(newContent)) {
                newContent = newContent.replace(re, '');
                this.isToWhatbot = true;
            }
        }
        this._content = newContent;
    }

    /** Context of the message */
    context: string;

    /** Timestamp of the message, as a Date */
    timestamp: Date;


    /** if the message was private or posted in a public channel */
    isPrivate: boolean = false;

    /** if the message called the bot out by name */
    isToWhatbot: boolean = false;

    /** if this message should not be processed by seen or other monitors */
    isInvisible: boolean = false;

    constructor(props: Partial<Message>) {
        Object.assign(this, props);
    }
}
