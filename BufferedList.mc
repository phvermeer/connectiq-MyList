import Toybox.Timer;
import Toybox.Lang;

module MyList{
    class BufferedList extends FilteredList{
        hidden var fifo as List = new MyList.List();
        hidden var timer as Timer.Timer = new Timer.Timer();
        hidden var loading as Boolean = false;
        hidden var interval as Number;
        hidden var batchCount as Number;
        hidden var maxCount as Number;
        hidden var reducedCount as Number;
        var onReady as Null | Method() as Void;

        function initialize(options as {
            :interval as Number, // interval[msec] to process items from buffer
            :batchCount as Number, // amount of items to process each time
            :maxCount as Number,
            :reducedCount as Number,
            :onReady as Method() as Void,
        }){
            FilteredList.initialize();
            interval = options.hasKey(:interval) ? options.get(:interval) as Number : 50;
            batchCount = options.hasKey(:batchCount) ? options.get(:batchCount) as Number : 40;
            maxCount = options.hasKey(:maxCount) ? options.get(:maxCount) as Number : 60;
            reducedCount = options.hasKey(:reducedCount) ? options.get(:reducedCount) as Number : (maxCount * 3 / 4).toNumber();
            onReady = options.get(:onReady) as Null | Method() as Void;
        }

        function add(object as Object) as Void{
            fifo.add(object);
            if(!loading){
                timer.start(method(:process), interval, true);
                loading = true;
            }
        }

        function process() as Void{
            if(size() > maxCount){
                // keep size within range
                filterSize(reducedCount);
            }else{
                var counter = 0;
                while(fifo.first()){
                    // get item from fifo
                    var object = fifo.current() as Object;
                    fifo.remove();

                    // add item to final destination
                    FilteredList.add(object);
                    
                    // limit number of processed new items
                    counter++;
                    if(counter>batchCount){
                        break;
                    }
                }
            }
            // check if timer can be stopped
            if(size() <= maxCount && fifo.size() == 0){
                timer.stop();
                loading = false;
                if(onReady != null){
                    onReady.invoke();
                }
            }
        }

        function isLoading() as Boolean{
            return loading;
        }
    }
}