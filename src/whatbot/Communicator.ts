import { factory } from './Logger';
import { Message } from './Message';

const log = factory.getLogger('Communicator');

export interface Communicator {
    config: any;
    name: string;
    me: string;
    ignore: boolean;

    connect();

    disconnect?();

    deliverMessage(message: Message);

    formatUser(user: string);

    sendMessage(message: Message);

    notify(context: string, content: string);
}