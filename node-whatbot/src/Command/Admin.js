import Command from './Command.js';

class Admin extends Command {
  register() {
    this.priority = 'Primary';
    this.requireDirect = false;

    this.command('refresh');
    this.command('version');
    this.command('rehash');
    this.command('error');
    this.command('alias');
    this.command('unalias');
    this.command('convertalias');
  }

  async refresh(message) {
    if (!this._hasPermission(message)) return null;
    
    this.controller.buildCommandMap();
    const count = this.controller.commandName ? this.controller.commandName.length : 0;
    return `Rebuilt command set: ${count} commands loaded.`;
  }

  async version(message) {
    if (!this._hasPermission(message)) return null;
    return `whatbot ${this.parent.version}`;
  }

  async rehash(message) {
    if (!this._hasPermission(message)) return null;
    
    this.log.write('Rehash requested - restarting process...');
    process.exit(0);
  }

  async error(message) {
    if (!this._hasPermission(message)) return null;
    return this.log.lastError || 'No recent errors.';
  }

  async alias(message, captures) {
    if (!this._hasPermission(message)) return null;

    const args = captures.join(' ').split(/\s+/);
    const [user, alias] = args;
    
    if (!user || !alias) return null;

    const owner = await this.model('UserAlias').userForAlias(alias);
    if (owner) {
      return `The alias "${alias}" is already set for user "${owner}".`;
    }

    const aliases = await this.model('UserAlias').aliasesForUser(alias);
    if (aliases && aliases.length > 0) {
      return `The alias "${alias}" is already a user with other aliases.`;
    }

    const result = await this.model('UserAlias').alias(user, alias);
    if (result) {
      return `The user "${user}" is now also known as "${alias}".`;
    }
    
    return null;
  }

  async unalias(message, captures) {
    if (!this._hasPermission(message)) return null;

    const args = captures.join(' ').split(/\s+/);
    const [user, alias] = args;
    
    if (!user || !alias) return null;

    const result = await this.model('UserAlias').remove(user, alias);
    if (result) {
      return 'Removed.';
    }

    return 'That combination was not found.';
  }

  async convertalias(message, captures) {
    if (!this._hasPermission(message)) return null;

    const alias = captures.join(' ').trim();
    if (!alias) return null;

    const lcalias = alias.toLowerCase();
    const user = await this.model('UserAlias').userForAlias(lcalias);
    
    if (!user) {
      return 'That alias is not assigned to a user.';
    }

    const karmas = await this.model('Karma').search({ 
      user: { LIKE: lcalias } 
    });
    for (const karma of karmas) {
      karma.user = user;
      await karma.save();
    }

    const subjectKarmas = await this.model('Karma').search({ 
      subject: lcalias 
    });
    for (const karma of subjectKarmas) {
      karma.subject = user;
      await karma.save();
    }

    return 'Done.';
  }

  _hasPermission(message) {
    return (
      this.myConfig &&
      this.myConfig.user &&
      message.from === this.myConfig.user
    );
  }

  help() {
    return [
      'Admin provides administrative commands for whatbot management.',
      'Commands (admin user only):',
      ' * refresh - Rebuild command map',
      ' * version - Show whatbot version',
      ' * rehash - Restart the bot',
      ' * error - Show last error',
      ' * alias <user> <alias> - Create user alias',
      ' * unalias <user> <alias> - Remove user alias',
      ' * convertalias <alias> - Convert karma from alias to canonical user'
    ];
  }
}

export default Admin;
