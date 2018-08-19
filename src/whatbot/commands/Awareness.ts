import { factory } from '../Logger';
import { Command, SimpleCommand } from '../Command';
import { Message } from '../Message';

const log = factory.getLogger('Awareness');

export class Awareness implements Command {
    requireDirect = false;
    
    @SimpleCommand()
    hi() {
        return 'hi';
    }
}
