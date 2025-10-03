import Component from '../Component.js';

class Timer extends Component {
  constructor() {
    super();
    this._name = 'Timer';
    this._me = 'Timer';
    this.timeQueue = [];
    this.nextTime = 0;
    this.intervalHandle = null;
  }

  async connect() {
    this.intervalHandle = setInterval(() => {
      this.eventLoop();
    }, 1000);
    this.log.write('Timer started.');
  }

  async disconnect() {
    if (this.intervalHandle) {
      clearInterval(this.intervalHandle);
      this.intervalHandle = null;
    }
    this.log.write('Timer stopped.');
  }

  name() {
    return this._name;
  }

  me() {
    return this._me;
  }

  enqueue(time, callback, ...args) {
    if (time < 86400) {
      time = Math.floor(Date.now() / 1000) + time;
    }

    const newItem = [time, callback, ...args];
    this.timeQueue.push(newItem);
    
    this.timeQueue.sort((a, b) => a[0] - b[0]);
    
    if (this.timeQueue.length > 0) {
      this.nextTime = this.timeQueue[0][0];
    }
  }

  remove(time, callback, ...args) {
    const matchItem = [time, callback, ...args];
    
    for (let index = 0; index < this.timeQueue.length; index++) {
      const item = this.timeQueue[index];
      
      if (item.length !== matchItem.length) continue;
      
      let match = true;
      for (let i = 0; i < item.length; i++) {
        if (item[i] !== matchItem[i]) {
          match = false;
          break;
        }
      }
      
      if (match) {
        this.timeQueue.splice(index, 1);
        
        if (index === 0) {
          if (this.timeQueue.length > 0) {
            this.nextTime = this.timeQueue[0][0];
          } else {
            this.nextTime = 0;
          }
        }
        
        return true;
      }
    }
    
    return false;
  }

  removeWhereArg(argIndex, match) {
    for (let index = 0; index < this.timeQueue.length; index++) {
      const item = this.timeQueue[index];
      
      if (!item[2] || item[2] !== match) continue;
      
      this.timeQueue.splice(index, 1);
      
      if (index === 0) {
        if (this.timeQueue.length > 0) {
          this.nextTime = this.timeQueue[0][0];
        } else {
          this.nextTime = 0;
        }
      }
      
      return true;
    }
    
    return false;
  }

  eventLoop() {
    const next = this.nextTime;
    if (!next) return;

    const now = Math.floor(Date.now() / 1000);
    if (now < next) return;

    if (this.timeQueue.length > 0) {
      const [when, callback, ...args] = this.timeQueue[0];
      
      if (when > now) {
        this.log.error('nextTime in timer was not the same as the first item in the queue...');
      } else {
        callback(...args);
        this.timeQueue.shift();
        
        if (this.timeQueue.length > 0) {
          this.nextTime = this.timeQueue[0][0];
        } else {
          this.nextTime = 0;
        }
      }
    }
  }
}

export default Timer;
