import Toybox.Timer;
import Toybox.Lang;

module MyList{
    class BufferedList extends FilteredList{
        class ListenerDummy{
            function onReady(sender as Object) as Void{
                
            }
        }
        typedef IListener as interface{
            function onReady(sender as Object) as Void;
        };

        hidden var fifo as List = new MyList.List();
        hidden var timer as Timer.Timer = new Timer.Timer();
        hidden var loading as Boolean = false;
        hidden var interval as Number;
        hidden var batchCount as Number;
        hidden var maxCount as Number;
        hidden var reducedCount as Number;
        hidden var listener as WeakReference?;

        function initialize(options as {
            :interval as Number, // interval[msec] to process items from buffer
            :batchCount as Number, // amount of items to process each time
            :maxCount as Number,
            :reducedCount as Number,
            :listener as Object,
        }){
            FilteredList.initialize();
            interval = options.hasKey(:interval) ? options.get(:interval) as Number : 200;
            batchCount = options.hasKey(:batchCount) ? options.get(:batchCount) as Number : 40;
            maxCount = options.hasKey(:maxCount) ? options.get(:maxCount) as Number : 60;
            reducedCount = options.hasKey(:reducedCount) ? options.get(:reducedCount) as Number : (maxCount * 3 / 4).toNumber();
            if(options.hasKey(:listener)){
                setListener(options.get(:listener));
            }
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
                var object = fifo.first();
                while(object != null){
                    fifo.remove();

                    // add item to final destination
                    FilteredList.add(object);
                    
                    // limit number of processed new items
                    counter++;
                    if(counter > batchCount){
                        break;
                    }
                    // get next item from fifo
                    object = fifo.first();
                }
            }
            // check if timer can be stopped
            if(size() <= maxCount && fifo.size() == 0){
                timer.stop();
                loading = false;
                notifyListener();
            }
        }

        function cancel() as Void{
            timer.stop();
        }

        function isLoading() as Boolean{
            return loading;
        }

        // *******************************
        // Listener
        function setListener(listener as Object|Null) as Void{
            self.listener = (listener != null && (listener as IListener) has :onReady)
                ? listener.weak()
                : null;
        }
        function getListener() as IListener|Null{
            return (listener != null) ? (listener.get() as IListener) : null;
        }
        function notifyListener() as Void{
            var l = getListener();
            if(l != null){
                l.onReady(self);
            }
        }
    }
}