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
			return new RankedItem(object) as List.ListItem;
		}

		hidden function updateRanking(item as RankedItem) as Void{
			var newRankValue = null;
			var previous = item.previous;
			var next = item.next;
			if(item != null && previous != null && next != null){
				// calculate
				newRankValue = (item.object as IRankable).getRankValue(previous.object, next.object);
			}
			if(newRankValue != item.rankValue){
				item.rankValue = newRankValue;
				var lower = item.lowerRanked;
				var higher = item.higherRanked;

				// remove from current ranking order
				if(lower != null){
					lower.higherRanked = higher;
				}
				if(higher != null){
					higher.lowerRanked = lower;
				}
				if(_lowestRanked == item){
					_lowestRanked = item.higherRanked;
				}

				if(newRankValue == null){
					// if no ranking value is available, then exclude from the ranking
					item.lowerRanked = null;
					item.higherRanked = null;
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
						item.lowerRanked = lower;
						item.higherRanked = higher;
						if(lower != null){
							lower.higherRanked = item;
						}
						if(higher != null){
							higher.lowerRanked = item;
						}
					}

					// update lowest ranked
					if(item.lowerRanked == null){
						_lowestRanked = item;
					}
				}
			}
		}

		public function refreshRanking() as Void{
			// this function will update all rankValues and rankingOrders
			var item = _first;
			while(item != null){
				updateRanking(item as RankedItem);
				item = item.next;
			}
		}

		protected function _add(item as List.ListItem, ref as List.ListItem?) as Void{
			List._add(item, ref);
			if(item.object == null){
				// previous or next also null => skip insert
				var previous = (item.previous != null) ? (item.previous as List.ListItem).object : null;
				var next = (item.next != null) ? (item.next as List.ListItem).object : null;
				if(previous == null || next == null){
					List._remove(item);
				}
			}

			// Update the rank values
			updateRanking(item as RankedItem);
			if(item.previous != null){
				updateRanking(item.previous as RankedItem);
			}
			if(item.next != null){
				updateRanking(item.next as RankedItem);
			}
		}
		protected function _remove(item as List.ListItem) as Void{
			// remove from list
			var item_ = item as RankedItem;
			var previous = item_.previous;
			var next = item_.next;
			List._remove(item_);

			// Update the rank values (keep in mind that item is deleted and has no relations to prev and next)
			updateRanking(item_);
			if(previous != null){
				updateRanking(previous as RankedItem);
			}
			if(next != null){
				updateRanking(next as RankedItem);
			}
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
				_remove(_lowestRanked as RankedItem);
			}
		}
	}
}