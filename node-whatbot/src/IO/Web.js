import Component from '../Component.js';

class Web extends Component {
  constructor(config) {
    super();
    this.myConfig = config?.my_config || {};
    this._name = 'Web';
    this._me = 'Web';
    this.server = null;
    this.routes = {};
    
    this.myConfig.port = this.myConfig.port || 2301;
    this.myConfig.url = this.myConfig.url || `http://localhost:${this.myConfig.port}`;
  }

  async connect() {
    try {
      const express = await import('express');
      const app = express.default();

      // Middleware
      app.use(express.default.json());
      app.use(express.default.urlencoded({ extended: true }));

      // Log all requests
      app.use((req, res, next) => {
        res.on('finish', () => {
          const route = this._findMatchingRoute(req.path);
          this.logResponse(res.statusCode, req, route);
        });
        next();
      });

      // Route handler
      app.all('*', async (req, res) => {
        const url = req.path;
        
        // Find matching route
        for (const path of Object.keys(this.routes).sort((a, b) => b.localeCompare(a))) {
          const regex = new RegExp(`^${path}$`);
          if (regex.test(url)) {
            const info = this.routes[path];
            try {
              const result = await info.callback(info.command, req, res);
              if (result && !res.headersSent) {
                if (Array.isArray(result) && result.length >= 4) {
                  // [statusCode, statusText, headers, body]
                  const [status, , headers, body] = result;
                  res.status(status);
                  if (headers) {
                    Object.entries(headers).forEach(([key, value]) => {
                      res.set(key, value);
                    });
                  }
                  res.send(body);
                } else {
                  res.send(result);
                }
              }
              return;
            } catch (err) {
              if (!res.headersSent) {
                res.status(500).type('text/plain').send('internal server error');
              }
              this.log.error(`Web error for ${path}: ${err.message}`);
              return;
            }
          }
        }
        
        if (!res.headersSent) {
          res.status(404).type('text/plain').send('not found');
        }
      });

      // Start server
      this.server = app.listen(this.myConfig.port, () => {
        this.log.write(`HTTP server started on port ${this.myConfig.port}.`);
      });

    } catch (err) {
      if (err.code === 'ERR_MODULE_NOT_FOUND') {
        this.log.error('Express module not available. Install with: npm install express');
        throw new Error('Express module not available');
      }
      throw err;
    }
  }

  async disconnect() {
    if (this.server) {
      await new Promise((resolve) => {
        this.server.close(resolve);
      });
      this.server = null;
    }
  }

  name() {
    return this._name;
  }

  me() {
    return this._me;
  }

  addDispatch(command, path, callback) {
    this.routes[path] = {
      command: command,
      callback: callback
    };
  }

  logResponse(code, req, path) {
    this.log.write(
      `(Web) ${req.ip} ${code} ${req.method} ${req.originalUrl} [${path || 'none'}]`
    );
  }

  _findMatchingRoute(url) {
    for (const path of Object.keys(this.routes).sort((a, b) => b.localeCompare(a))) {
      const regex = new RegExp(`^${path}$`);
      if (regex.test(url)) {
        return path;
      }
    }
    return null;
  }

  eventLoop() {
    // No-op for web
  }
}

export default Web;
