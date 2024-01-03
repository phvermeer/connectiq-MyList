import Toybox.Lang;
import Toybox.System;

module MyList{
	class FilteredList extends List{
		// filter based upon evaluation of each item with their relation to the predecescor and successor
		typedef IRankable as interface{
			function getRankValue(predecessor as Object, successor as Object) as Numeric;
		};

		class RankedItem extends List.ListItem{
			var rankValue as Numeric?;
			var lowerRanked as RankedItem?;
			var higherRanked as RankedItem?;
			function initialize(object as Object){
				ListItem.initialize(object);
			}
		}

		hidden var _lowestRanked as RankedItem?;

		function initialize(){
			List.initialize();
		}

		protected function createItem(object as Object) as List.ListItem{
			if((object as IRankable) has :getRankValue){
				return new RankedItem(object) as List.ListItem;
			}else{
				throw new InvalidValueException("object should have the function getRankValue()");
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
				var lower = current.lowerRanked;
				var higher = current.higherRanked;

				// remove from current ranking order
				if(lower != null){
					lower.higherRanked = higher;
				}
				if(higher != null){
					higher.lowerRanked = lower;
				}
				if(_lowestRanked == current){
					_lowestRanked = current.higherRanked;
				}

				if(newRankValue == null){
					// if no ranking value is available, then exclude from the ranking
					current.lowerRanked = null;
					current.higherRanked = null;
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
							higher = higher.higherRanked;
						}
						// (re)insert on the new ranking position
						current.lowerRanked = lower;
						current.higherRanked = higher;
						if(lower != null){
							lower.higherRanked = current;
						}
						if(higher != null){
							higher.lowerRanked = current;
						}
					}

					// update lowest ranked
					if(current.lowerRanked == null){
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

		protected function _add(item as List.ListItem, index as Number) as Void{
			List._add(item, index);

			// Update the rank values
			var count = _items.size();
			var current = item as RankedItem;
			var previous = (index > 0) ? _items[index-1] as RankedItem : null;
			var next = (index < count-1) ? _items[index+1] as RankedItem : null;

			updateRanking(previous, current, next);
			if(previous != null){
				var prevprev = (index > 1) ? _items[index-2] as RankedItem: null;
				updateRanking(prevprev, previous, current);
			}
			if(next != null){
				var nextnext = (index < count-2) ? _items[index+2] as RankedItem : null;
				updateRanking(current, next, nextnext);
			}
		}

		protected function _remove(index as Number|Null, item as List.ListItem|Null) as Boolean{
			// remove from list
			if(index == null && item != null){
				index = _items.indexOf(item);
			}else if(item == null && index != null){
				item = _items[index];
			}
			var removed = List._remove(index, item);


			if(removed && index != null){
				var count = _items.size();
				var old = item as RankedItem;
				var previous = (index > 0) ? _items[index-1] as RankedItem : null;
				var next = (index < count) ? _items[index] as RankedItem : null;

				// Update the rank values (keep in mind that item is deleted and has no relations to prev and next)
				updateRanking(null, old, null);
				if(previous != null){
					var prevprev = (index > 1) ? _items[index-2] as RankedItem: null;
					updateRanking(prevprev, previous, next);
				}
				if(next != null){
					var nextnext = (index < count-2) ? _items[index+2] as RankedItem : null;
					updateRanking(previous, next, nextnext);
				}
			}

			return removed;
		}

		hidden function getRankValues() as Array<Numeric|Null>{
			// collect ranking values for evaluation
			var item = _lowestRanked;
			var array = [] as Array<Numeric|Null>;
			while(item != null){
				array.add(item.rankValue);
				item = item.higherRanked;
			}
			return array;
		}

		public function filterSize(maxSize as Number) as Void{
			// System.println(Lang.format("before filter: $1$", [getRankValues()]));
			while(_lowestRanked != null && size() > maxSize){
				// remove the item with the lowest rank untill the size is within the range
				_remove(null, _lowestRanked as RankedItem);
			}
		}
	}
}