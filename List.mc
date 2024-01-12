import Toybox.Lang;

module MyBarrel{
    (:lists)
    module Lists{
	class List{
		// This List will implement the interface IIterator as defined in the module MyGraph
		hidden var _index as Number = -1;
		hidden var _items as Array<Object> = [] as Array<Object>;

		public function add(object as Object) as Void{
			// Adds an item at the end of the array
			_items.add(object);
		}
		public function remove() as Boolean{
			// deletes the item at current position at moves the current pointer to the previous
			if(_index >= 0 && _index < _items.size()){
				var object = _items[_index] as Object;
				return _items.remove(object);
			}else{
				return false;
			}
		}
		public function clear() as Void{
			_index = -1;
			_items = [] as Array<Object>;
		}
		public function previous() as Object|Null{
			if(_index > 0){
				_index--;
				return _items[_index];
			}else{
				return null;
			}
		}
		public function next() as Object|Null{
			if(_index >= 0){
				_index++;
				if(_index < _items.size()){
					return _items[_index];
				}else{
					_index = -1;
				}
			}
			return null;
		}
		public function first() as Object|Null{
			if(_items.size() > 0){
				_index = 0;
				return _items[_index];
			}else{
				return null;
			}
		}
		public function last() as Object|Null{
			_index = _items.size() - 1;
			if(_index >= 0){
				return _items[_index];
			}else{
				return null;
			}
		}
		public function toArray() as Array<Object>{
			return _items.slice(null, null);
		}
		public function size() as Number{
			return _items.size();
		}
	}
}
}