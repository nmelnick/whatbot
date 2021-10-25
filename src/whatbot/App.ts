import { factory } from './Logger';

import * as version from 'project-version';
import * as fs from 'fs';

const log = factory.getLogger('App');

export class App {
    async start(): Promise<void> {
        log.info('Starting whatbot ' + version);
        await this.loadCommands();
    }

    async loadCommands(directory: string = 'src/whatbot/commands'): Promise<void> {
        return new Promise((resolve, reject) => {
            fs.readdir(directory, (err, files) => {
                if (err) {
                    log.error('Error reading commands directory "' + directory + '"', err);
                    reject(err);
                    return;
                }
                for (const file of files) {
                    import('./commands/' + file.replace('.ts', ''));
                }
              })
        })
    }
}
