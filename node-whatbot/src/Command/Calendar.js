import Command from './Command.js';

class Calendar extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.globalRegEx(/what day is .*?today/i, 'day');
    this.globalRegEx(/what time is it/i, 'time');
    this.command('day');
    this.command('time');
  }

  async day(message) {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    
    return `The date is ${year}/${month}/${day}.`;
  }

  async time(message) {
    const now = new Date();
    const hour = String(now.getHours()).padStart(2, '0');
    const minute = String(now.getMinutes()).padStart(2, '0');
    const second = String(now.getSeconds()).padStart(2, '0');
    
    return `The time is ${hour}:${minute}:${second}.`;
  }

  help() {
    return [
      'Calendar provides date and time information.',
      'Commands:',
      ' * "what day is today" - Show current date',
      ' * "what time is it" - Show current time'
    ];
  }
}

export default Calendar;
