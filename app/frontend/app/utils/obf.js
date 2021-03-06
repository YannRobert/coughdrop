import EmberObject from '@ember/object';
import CoughDrop from '../app';
import evaluation from './eval';
import { later as runLater } from '@ember/runloop';

var handlers = {};
var obf = EmberObject.extend({
  parse: function(json) {
    var hash = JSON.parse(json);
    var id = (hash['id'] || 'b123') + 'b' + (new Date()).getTime() + "x" + Math.round(Math.random() * 9999);
    var board = CoughDrop.store.push({data: {
      id: id,
      type: 'board',
      attributes: {}
    }});
    board.set('local_only', true);
    board.set('grid', hash['grid']);
    
    board.set('id', );
    board.set('permissions', {view: true});
    hash['background'] = hash['background'] || {};
    board.set('background', {
      image: hash['background']['image'] || hash['background']['image_url'],
      image_exclusion: hash['background']['ext_coughdrop_image_exclusion'],
      color: hash['background']['color'],
      position: hash['background']['position'],
      text: hash['background']['text'],
      prompt: hash['background']['prompt'] || hash['background']['prompt_text'],
      delay_prompts: hash['background']['delay_prompts'] || hash['background']['delayed_prompts'],
      delay_prompt_timeout: hash['background']['delay_prompt_timeout']
    })
    board.set('text_only', hash['text_only']);
    board.set('hide_empty', true);
    board.set('key', hash['key'] || "obf/whatever");
    var image_urls = {};
    var sound_urls = {};
    var buttons = [];
    (hash['buttons'] || []).forEach(function(b) {
      var img = b.image_id && hash['images'].find(function(i) { return i.id == b.image_id; });
      if(img) { image_urls[b.image_id] = img.url; }
      var snd = b.sound_id && hash['sounds'].find(function(s) { return s.id == b.sound_id; });
      if(snd) { sound_urls[b.sound_id] = snd.url; }
      buttons.push(b);
      // TODO: include attributions somewhere
    });
    board.set('buttons', buttons);
    board.set('image_urls', image_urls);
    board.set('sound_urls', sound_urls);
    return board;
  },
  register: function(prefix, render) {
    handlers[prefix] = render;
  },
  lookup: function(key) {
    for(var prefix in handlers) {
      var re = new RegExp("^" + prefix);
      if(key.match(re)) {
        var opts = handlers[prefix](key);
        if(opts) {
          var board = obf.parse(opts.json);
          board.set('rendered', (new Date()).getTime());
          if(opts.handler) {
            board.set('button_handler', opts.handler);
          }
          return board;
        }
      }
    }
    return null;
  },
  shell: function(rows, columns) {
    var grid = [];
    for(var idx = 0; idx < rows; idx++) {
      var row = [];
      for(var jdx = 0; jdx < columns; jdx++) {
        row.push(null);
      }
      grid.push(row);
    }
    var shell = {
      format: 'open-board-0.1',
      license: {type: 'private'},
      background: {},
      buttons: [],
      grid: {
        rows: rows,
        columns: columns,
        order: grid
      },
      images: [],
      sounds: []
    };
    shell.id_index = 0;
    shell.to_json = function() {
      return JSON.stringify(shell, 2);
    };
    shell.add_button = function(button, row, col) {
      button.id = button.id || "btn_" + (++shell.id_index);
      if(button.image) {
        var img = Object.assign({}, button.image);
        img.id = "img_" + (++shell.id_index);
        shell.images.push(img);
        button.image_id = img.id;
        delete button['image'];
      }
      if(button.sound) {
        var snd = Object.assign({}, button.sound);
        snd.id = "snd_" + (++shell.id_index);
        shell.sounds.push(snd);
        button.sound_id = snd.id;
        delete button['sound'];
      }
      shell.buttons.push(button);
      if(row >= 0 && col >= 0 && row < shell.grid.rows && col < shell.grid.columns) {
        if(!shell.grid.order[row][col]) {
          shell.grid.order[row][col] = button.id;
        }
      }
    };
    return shell;
  }
}).create();

obf.register("eval", evaluation.callback);
obf.eval = evaluation;

obf.register("emergency", function(key) {

});
window.obf = obf;

export default obf;
