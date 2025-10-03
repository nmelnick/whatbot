/**
 * Quote.js - Quote storage command
 * Matches Whatbot::Command::Quote from Perl version (simplified, no web)
 */

import Command from './Command.js';

class Quote extends Command {
  register() {
    this.commandPriority = 'Extension';
    this.requireDirect = false;
    
    // quote <user> "<quote>"
    this.globalRegEx('^quote (.*?)[,\\:]? "(.*?)"\\s*$', 'addQuote');
    
    // quote <id>
    this.globalRegEx('^quote (\\d+)$', 'getQuoteById');
  }

  addQuote(message, captures) {
    const quoted = captures[0];
    const content = captures[1];
    
    try {
      const quote = this.model('quote').create({
        user: message.from,
        quoted: quoted,
        content: content
      });
      
      return `Quote #${quote.quoteId} added to quoteboard.`;
    } catch (error) {
      if (error.name === 'QuoteExistsError') {
        return `Sorry, this was already quoted by ${error.user}.`;
      }
      return 'Could not create quote.';
    }
  }

  getQuoteById(message, captures) {
    const quoteId = parseInt(captures[0]);
    const quote = this.model('quote').find(quoteId);
    
    if (quote) {
      return `<${quote.quoted}> ${quote.content}`;
    }
    
    return `Could not find quote #${quoteId}.`;
  }

  help() {
    return 'Add quotes with: quote <user> "<text>". View quotes with: quote <number>.';
  }
}

export default Quote;
