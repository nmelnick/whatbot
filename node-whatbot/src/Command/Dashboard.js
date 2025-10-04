import Command from './Command.js';

class Dashboard extends Command {
  register() {
    this.priority = 'Core';
    this.requireDirect = false;

    if (this.ios && this.ios.Web) {
      this.ios.Web.addDispatch(this, '/', this.dashboard.bind(this));
    }
  }

  async dashboard(req, res) {
    const applications = [];
    
    const html = `
<!DOCTYPE html>
<html>
<head>
  <title>whatbot Dashboard</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; }
    h2 { color: #333; }
    .list-group { list-style: none; padding: 0; }
    .list-group-item { 
      display: block; 
      padding: 10px 15px; 
      margin-bottom: 5px; 
      background: #f5f5f5; 
      text-decoration: none; 
      color: #333; 
      border-radius: 4px;
    }
    .list-group-item:hover { background: #e0e0e0; }
  </style>
</head>
<body>
  <h1>whatbot Dashboard</h1>
  <h2>Commands</h2>
  <div class="list-group">
    ${applications.length > 0 
      ? applications.map(app => `<a href="${app.url}" class="list-group-item">${app.name}</a>`).join('\n    ')
      : '<div class="list-group-item">No web-capable commands installed.</div>'}
  </div>
</body>
</html>`;

    return [200, 'OK', { 'Content-Type': 'text/html' }, html];
  }

  help() {
    const webUrl = this.ios?.Web?.myConfig?.url || 'http://localhost:2301';
    return `Dashboard is at ${webUrl}.`;
  }
}

export default Dashboard;
