#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H

enum{
	SENDER_QUEUE_SIZE=5,
	RECEIVER_QUEUE_SIZE=3,
	AM_SIMPLEROUTINGTREEMSG=22,
	AM_ROUTINGMSG=22,
	AM_NOTIFYPARENTMSG=12,
	SEND_CHECK_MILLIS=70000,
	TIMER_PERIOD_MILLI=150000,
	TIMER_FAST_PERIOD=200,
	TIMER_LEDS_MILLI=1000,

	//ADDED
	WINDOW_MILLI=80,
	EPOCH_PERIOD_MILLI=20000,
	AGGREGATION_TYPE_MIN=1,
	AGGREGATION_TYPE_SUM=2,
	AGGREGATION_TYPE_AVG=3,
	//END ADDED
};
/*uint16_t AM_ROUTINGMSG=AM_SIMPLEROUTINGTREEMSG;
uint16_t AM_NOTIFYPARENTMSG=AM_SIMPLEROUTINGTREEMSG;
*/

//ADDED
typedef nx_struct AggregationMin {
	//nx_uint16_t epoch;      // epoch number
	nx_uint8_t minVal;     // minimum value (used for MIN)
} AggregationMin;

typedef nx_struct AggregationSum {
	//nx_uint16_t epoch;      // epoch number
	nx_uint16_t sum;      // sum value (used for SUM)
} AggregationSum;

typedef nx_struct AggregationAvg {
	//nx_uint16_t epoch;      // epoch number
	nx_uint16_t sum;        // sum value (used for AVG)
	nx_uint16_t count;      // count of values (used for AVG)
} AggregationAvg;
//END ADDED


typedef nx_struct RoutingMsg{
	nx_uint8_t depth;
	nx_uint8_t aggType;     // ADDED
} RoutingMsg;


#endif
