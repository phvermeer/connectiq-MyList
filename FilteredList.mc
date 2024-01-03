import Toybox.Lang;
import Toybox.System;

module MyList{
	class FilteredList extends List{
		// filter based upon evaluation of each item with their relation to the predecescor and successor
		typedef IRankable as interface{
			function getRankValue(predecessor as Object, successor as Object) as Numeric;
		};

		class RankedItem{
			var object as Object;
			var rankValue as Numeric?;
			hidden var lowerRanked as WeakReference?;
			hidden var higherRanked as WeakReference?;
			function initialize(object as Object){
				self.object = object;
			}
			function getLowerRanked() as RankedItem?{
				return (lowerRanked != null) ? lowerRanked.get() as RankedItem? : null;
			}
			function getHigherRanked() as RankedItem?{
				return (higherRanked != null) ? higherRanked.get() as RankedItem? : null;
			}
			function setLowerRanked(item as RankedItem?) as Void{
				lowerRanked = (item != null) ? item.weak() : null;
			}
			function setHigherRanked(item as RankedItem?) as Void{
				higherRanked = (item != null) ? item.weak() : null;
			}
		}

		hidden var _lowestRanked as RankedItem?;

		function initialize(){
			List.initialize();
		}

		protected function createItem(object as Object) as RankedItem{
			if((object as IRankable) has :getRankValue){
				return new RankedItem(object);
			}else{
				throw new InvalidValueException("object should have implemented the function getRankValue()");
			}
		}

		hidden function updateRanking(previous as RankedItem|Null, current as RankedItem, next as RankedItem|Null) as Void{
			var newRankValue = null;
			if(current != null && previous != null && next != null){
				// calculate
				newRankValue = (current.object as IRankable).getRankValue(previous.object, next.object);
			}
			if(newRankValue != current.rankValue){
				current.rankValue = newRankValue;
				var lower = current.getLowerRanked();
				var higher = current.getHigherRanked();

				// remove from current ranking order
				if(lower != null){
					lower.setHigherRanked(higher);
				}
				if(higher != null){
					higher.setLowerRanked(lower);
				}
				if(_lowestRanked == current){
					_lowestRanked = current.getHigherRanked();
				}

				if(newRankValue == null){
					// if no ranking value is available, then exclude from the ranking
					current.setLowerRanked(null);
					current.setHigherRanked(null);
				}else{
					// search for the new ranking position (start at lowest)
					if(_lowestRanked != null){
						lower = null;
						higher = _lowestRanked;
						while(higher != null){
							if((higher.rankValue as Numeric) >= newRankValue){
								break;
							}
							lower = higher;
							higher = higher.getHigherRanked();
						}
						// (re)insert on the new ranking position
						current.setLowerRanked(lower);
						current.setHigherRanked(higher);
						if(lower != null){
							lower.setHigherRanked(current);
						}
						if(higher != null){
							higher.setLowerRanked(current);
						}
					}

					// update lowest ranked
					if(current.getLowerRanked() == null){
						_lowestRanked = current;
					}
				}
			}
		}

		public function refreshRanking() as Void{
			// this function will update all rankValues and rankingOrders
			var count = _items.size();
			if(count >= 2){
				var previous = _items[0] as RankedItem;
				var current = _items[1] as RankedItem;
				updateRanking(null, previous, current);
				for(var i=2; i<count; i++){
					var next = _items[i] as RankedItem;
					updateRanking(previous, current, next);
					previous = current;
					current = next;
				}
				updateRanking(previous, current, null);
			}
		}

		public function add(object as Object) as Void{
			var item = createItem(object);
			List.add(item);

			// Update the rank values
			var count = _items.size();
			if(count >= 3){
				var previous = _items[count-2] as RankedItem;
				var prevprev = _items[count-3] as RankedItem;

				updateRanking(prevprev, previous, item);
			}
		}

		protected function _remove(index as Number, item as RankedItem) as Boolean{
			if(_items[index].equals(item) && _items.remove(item)){
				var count = _items.size();
				var previous = (index > 0) ? _items[index-1] as RankedItem : null;
				var next = (index < count) ? _items[index] as RankedItem : null;

				// Update the rank values (keep in mind that item is deleted and has no relations to prev and next)
				updateRanking(null, item, null);
				if(previous != null){
					var prevprev = (index > 1) ? _items[index-2] as RankedItem: null;
					updateRanking(prevprev, previous, next);
				}
				if(next != null){
					var nextnext = (index < count-2) ? _items[index+2] as RankedItem : null;
					updateRanking(previous, next, nextnext);
				}
				return true;
			}
			return false;
		}
		public function remove() as Boolean{
			var item = _items[_index] as RankedItem;
			return _remove(_index, item);
		}
		protected function _removeItem(item as RankedItem) as Boolean{
			var index = _items.indexOf(item);
			return _remove(index, item);
		}

		public function filterSize(maxSize as Number) as Void{
			while(size() > maxSize && _lowestRanked != null){
				// remove the item with the lowest rank untill the size is within the range
				_removeItem(_lowestRanked);
			}
		}

		// override function to return the correct object
		public function first() as Object|Null{
			var item = List.first();
			return (item != null) ? (item as RankedItem).object : null;
		}
		public function last() as Object|Null{
			var item = List.last();
			return (item != null) ? (item as RankedItem).object : null;
		}
		public function next() as Object|Null{
			var item = List.next();
			return (item != null) ? (item as RankedItem).object : null;
		}
		public function previous() as Object|Null{
			var item = List.previous();
			return (item != null) ? (item as RankedItem).object : null;
		}
	}
}