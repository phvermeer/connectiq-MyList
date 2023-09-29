import Toybox.Lang;

module MyList{
	class List{
		class ListItem{
			var previous as ListItem?;
			var next as ListItem?;
			var object as Object;
			function initialize(object as Object){
				self.object = object;
			}
		}

		hidden var _size as Number = 0;
		hidden var _current as ListItem?;
		hidden var _first as ListItem?;
		hidden var _last as ListItem?;

		protected function createItem(object as Object) as ListItem{
			return new ListItem(object);
		}
		protected function _add(item as ListItem, ref as ListItem?) as Void{
			// inserts an item behind the ref item. if ref==null, the item is inserted at beginning
			if(_first!=null){
				if(ref!=null){
					item.previous = ref;
					var next = ref.next;
					if(next != null){
						next.previous = item;
						item.next = next;
					}else{
						_last = item;
					}
					ref.next = item;
				}else{
					_first.previous = item;
					item.next = _first;
					var next = _first.next;
					if(next != null){
						next.previous = item;
					}
					_first = item;
				}
			}else{
				//first item
				_first = item;
				_last = item;
				_current = item;
			}
			_size++;
		}
		protected function _remove(item as ListItem) as Void{
			// break links from other items in the list
			var previous = item.previous;
			var next = item.next;

			if(previous != null && next != null){
				previous.next = next;
				next.previous = previous;
			}else if(previous != null){
				previous.next = null;
				_last = previous;
			}else if(next != null){
				next.previous = null;
				_first = next;
			}else{
				_first = null;
				_last = null;
			}
			_size--;

			if(_current == item){
				// update current pointer
				_current = previous;
			}

			// break links to other items in the list
			item.previous = null;
			item.next = null;
		}

		public function add(object as Object) as Void{
			// Adds an item at the end of the list
			var item = createItem(object);
			_add(item, _last);
		}
		public function addAll(array as Array) as Void{
			for(var i=0; i<array.size(); i++){
				var item = createItem(array[i] as Object);
				_add(item, _last);
			}
		}
		public function remove() as Boolean{
			// deletes the item at current position at moves the current pointer to the previous
			if(_current != null){
				_remove(_current);
				return true;
			}
			return false;
		}
		public function removeAll() as Void{
			while(_first != null){
				_remove(_first);
			}
		}
		public function current() as Object?{
			if(_current != null){
				return _current.object;
			}
			return null;
		}
		public function previous() as Boolean{
			if(_current != null){
				_current = _current.previous;
			}
			return _current != null;
		}
		public function next() as Boolean{
			if(_current != null){
				_current = _current.next;
			}
			return _current != null;
		}
		public function first() as Boolean{
			_current = _first;
			return _current != null;
		}
		public function last() as Boolean{
			_current = _last;
			return _current != null;
		}
		public function toArray() as Array<Object>{
			var array = new [_size] as Array<Object>;
			var item = _first;
			var i = 0;
			while(item != null){
				array[i] = item.object;
				i++;
				item = item.next;
			}
			return array;
		}
		public function size() as Number{
			return _size;
		}
		public function insert(object as Object) as Void{
			var item = createItem(object);
			_add(item, _current);
		}
	}
}