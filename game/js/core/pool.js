/** pool.js — pooling de objetos para partículas/projéteis/inimigos (zero GC no laço quente). */

export class Pool {
  /**
   * @param {() => object} factory  cria um objeto novo
   * @param {(o:object) => void} reset  limpa o objeto ao devolver
   * @param {number} initial  pré-alocação
   * @param {number} max  teto de objetos vivos (descarta o mais antigo)
   */
  constructor(factory, reset, initial = 64, max = 4096) {
    this.factory = factory;
    this.resetFn = reset;
    this.free = [];
    this.active = [];
    this.max = max;
    this.created = 0;
    for (let i = 0; i < initial; i++) { this.free.push(factory()); this.created++; }
  }

  get() {
    let o;
    if (this.free.length) o = this.free.pop();
    else if (this.active.length >= this.max) { o = this.active.shift(); this.resetFn(o); }
    else { o = this.factory(); this.created++; }
    this.active.push(o);
    return o;
  }

  /** Devolve pelo índice do array ativo (uso com laço reverso). */
  releaseAt(i) {
    const o = this.active[i];
    const last = this.active.length - 1;
    if (i !== last) this.active[i] = this.active[last];
    this.active.pop();
    this.resetFn(o);
    this.free.push(o);
    return o;
  }

  release(o) {
    const i = this.active.indexOf(o);
    if (i >= 0) this.releaseAt(i);
  }

  releaseAll() {
    for (let i = this.active.length - 1; i >= 0; i--) this.releaseAt(i);
  }

  get count() { return this.active.length; }
  forEach(fn) { for (let i = 0; i < this.active.length; i++) fn(this.active[i], i); }
}
