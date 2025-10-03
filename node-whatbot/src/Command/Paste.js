import Command from './Command.js';

class Paste extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.command('add');
    this.command('get');
    this.command('list');
  }

  async add(message, captures) {
    const content = captures.join(' ');
    if (!content) {
      return 'Usage: paste add <content>';
    }

    const paste = await this.model('Paste').create({
      user: message.from,
      destination: message.to,
      summary: 'Command line paste',
      content: content
    });

    if (paste) {
      return `Paste created with ID ${paste.paste_id}. Use "paste get ${paste.paste_id}" to view.`;
    }

    return 'Error creating paste.';
  }

  async get(message, captures) {
    const id = parseInt(captures[0]);
    if (isNaN(id)) {
      return 'Usage: paste get <id>';
    }

    const paste = await this.model('Paste').find(id);
    if (!paste) {
      return `No paste found with ID ${id}.`;
    }

    const date = new Date(paste.timestamp * 1000).toISOString();
    return [
      `Paste #${paste.paste_id} by ${paste.user} on ${date}`,
      `Summary: ${paste.summary}`,
      `Content: ${paste.content}`
    ];
  }

  async list(message) {
    const pastes = await this.model('Paste').search({}, { 
      _order_by: 'paste_id DESC',
      _limit: 10
    });

    if (!pastes || pastes.length === 0) {
      return 'No pastes found.';
    }

    const out = ['Recent pastes:'];
    for (const paste of pastes) {
      const date = new Date(paste.timestamp * 1000).toISOString().split('T')[0];
      out.push(`${paste.paste_id}. ${paste.summary} by ${paste.user} (${date})`);
    }

    return out;
  }

  help() {
    return [
      'Paste provides simple paste storage and retrieval.',
      'Commands:',
      ' * paste add <content> - Create a new paste',
      ' * paste get <id> - View a paste',
      ' * paste list - List recent pastes',
      'Note: Web interface requires Web IO module'
    ];
  }
}

export default Paste;
