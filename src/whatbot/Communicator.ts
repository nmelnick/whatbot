import { Config } from './Config';
import { factory } from './Logger';
import { Message } from './Message';

const log = factory.getLogger('Communicator');

export interface Communicator {
    config: Config;
    name: string;
    me: string;
    ignore: boolean;

    connect(): Promise<void>;

    disconnect?(): Promise<void>;

    deliverMessage(message: Message): Promise<void>;

    formatUser(user: string): Promise<string>;

    sendMessage(message: Message): Promise<void>;

    notify(context: string, content: string): Promise<void>;
}
