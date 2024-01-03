import Toybox.Lang;

module MyList{
	class List{
		class ListItem{
			var object as Object;
			function initialize(object as Object){
				self.object = object;
			}
		}

		protected var _index as Number = -1;
		protected var _items as Array<ListItem> = [] as Array<ListItem>;

		protected function createItem(object as Object) as ListItem{
			return new ListItem(object);
		}

		protected function _add(item as ListItem, index as Number) as Void{
			var count = _items.size();
			if(index < 0 || index > count){
				throw new InvalidValueException(Lang.format("index out of bounds (index=)", [index]));
			}
			if(index >= count-1){
				// add at the end
				_items.add(item);
			}else if(index < 0){
				// insert at the beginning
				var items = [item] as Array<ListItem>;
				items.addAll(_items);
				_items = items;
			}else{
				// insert
				var items = _items.slice(null, index);
				items.add(item);
				items.addAll(_items.slice(index, null));
				_items = items;
			}
		}
		protected function _remove(index as Number|Null, item as ListItem|Null) as Boolean{
			if(item == null && index != null){
				// remove based upon index
				if(index >= 0){
					item = _items[index];
				}else{
					return false;
				}
			}
			return (item != null) ? _items.remove(item) : false;
		}

		public function add(object as Object) as Void{
			// Adds an item at the end of the array
			var i = _items.size();
			var item = createItem(object);
			_add(item, i);
		}
		public function remove() as Boolean{
			// deletes the item at current position at moves the current pointer to the previous
			if(_remove(_index, null)){
				_index--;
				return true;
			}else{
				return false;
			}
		}
		public function clear() as Void{
			_index = -1;
			_items = [] as Array<ListItem>;
		}
		public function previous() as Object|Null{
			if(_index > 0){
				_index--;
				return _items[_index].object;
			}else{
				return null;
			}
		}
		public function next() as Object|Null{
			if(_index >= 0){
				_index++;
				if(_index < _items.size()){
					return _items[_index].object;
				}else{
					_index = -1;
				}
			}
			return null;
		}
		public function first() as Object|Null{
			if(_items.size() > 0){
				_index = 0;
				return _items[_index].object;
			}else{
				return null;
			}
		}
		public function last() as Object|Null{
			_index = _items.size() - 1;
			if(_index >= 0){
				return _items[_index].object;
			}else{
				return null;
			}
		}
		public function toArray() as Array<Object>{
			var count = _items.size();
			var objects = new Array<Object>[count];
			for(var i=0; i<count; i++){
				objects[i] = _items[i].object;
			}
			return objects;
		}
		public function size() as Number{
			return _items.size();
		}
		public function insert(object as Object) as Void{
			var item = createItem(object);
			_add(item, _index);
		}
	}
}