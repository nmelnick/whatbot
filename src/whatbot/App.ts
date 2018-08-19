import { factory } from './Logger';

import * as version from 'project-version';
import * as fs from 'fs';

const log = factory.getLogger('App');

export class App {
    start() {
        log.info('Starting whatbot ' + version);
        this.loadCommands();
    }

    loadCommands(directory: string = 'src/whatbot/commands') {
        fs.readdir(directory, (err, files) => {
            if (err) {
                log.error('Error reading commands directory "' + directory + '"', err);
                return;
            }
            files.forEach(file => {
                import('./commands/' + file.replace('.ts', '')).then(() => {});
            });
          })
    }
}
