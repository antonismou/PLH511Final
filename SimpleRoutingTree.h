#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H

enum{
	SENDER_QUEUE_SIZE=5,
	RECEIVER_QUEUE_SIZE=3,
	AM_SIMPLEROUTINGTREEMSG=22,
	AM_ROUTINGMSG=22,
	//AM_NOTIFYPARENTMSG=12,
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

	//ADDED PHACE 2
	AGGREGATION_TYPE_MIN_GROUP=4,
	AGGREGATION_TYPE_SUM_GROUP=5,
	ID_MSG_MIN_GROUP_1_2=112,
	ID_MSG_MIN_GROUP_1_3=113,
	ID_MSG_MIN_GROUP_2_3=123,
	ID_MSG_MIN_GROUP_1_2_3=44,
	
	ID_MSG_SUM_GROUP_1_2=212,
	ID_MSG_SUM_GROUP_1_3=213,
	ID_MSG_SUM_GROUP_2_3=223,
	ID_MSG_SUM_GROUP_1_2_3=55,
	//END PHACE 2
};
/*uint16_t AM_ROUTINGMSG=AM_SIMPLEROUTINGTREEMSG;
uint16_t AM_NOTIFYPARENTMSG=AM_SIMPLEROUTINGTREEMSG;
*/
//ADDED PHACE 2

typedef nx_struct Sum12Group{
	nx_uint16_t sumGroup1;
	nx_uint16_t sumGroup2;
}Sum12Group;

typedef nx_struct Sum13Group{
	nx_uint16_t sumGroup1;
	nx_uint16_t sumGroup3;
}Sum13Group;

typedef nx_struct Sum23Group{
	nx_uint16_t sumGroup2;
	nx_uint16_t sumGroup3;
}Sum23Group;

typedef nx_struct Sum3Group{
	nx_uint16_t sumGroup1;
	nx_uint16_t sumGroup2;
	nx_uint16_t sumGroup3;
}Sum3Group;

typedef nx_struct Min12Group{
	nx_uint8_t minGroup1;
	nx_uint8_t minGroup2;
}Min12Group;

typedef nx_struct Min13Group{
	nx_uint8_t minGroup1;
	nx_uint8_t minGroup3;
}Min13Group;

typedef nx_struct Min23Group{
	nx_uint8_t minGroup2;
	nx_uint8_t minGroup3;
}Min23Group;

typedef nx_struct Min3Group{
	nx_uint8_t minGroup1;
	nx_uint8_t minGroup2;
	nx_uint8_t minGroup3;
}Min3Group;

//END PHACE 2


//ADDED
typedef nx_struct AggregationMin {
	nx_uint8_t minVal;     // minimum value (used for MIN)
} AggregationMin;

typedef nx_struct AggregationSum {
	nx_uint16_t sum;      // sum value (used for SUM)
} AggregationSum;

typedef nx_struct AggregationAvg {
	nx_uint16_t sum;        // sum value (used for AVG)
	nx_uint8_t count;      // count of values (used for AVG)
} AggregationAvg;
//END ADDED


typedef nx_struct RoutingMsg{
	nx_uint8_t depth;
	nx_uint8_t aggType;     // ADDED
} RoutingMsg;


#endif
