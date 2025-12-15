#include "SimpleRoutingTree.h"
#ifdef PRINTFDBG_MODE
	#include "printf.h"
#endif

module SRTreeC
{
	uses interface Boot;
	uses interface Leds;
	uses interface SplitControl as RadioControl;
#ifdef SERIAL_EN
	uses interface SplitControl as SerialControl;
#endif

	uses interface Packet as RoutingPacket;
	uses interface AMSend as RoutingAMSend;
	uses interface AMPacket as RoutingAMPacket;
	/*removed bevause tag not using this
		uses interface AMSend as NotifyAMSend;
		uses interface AMPacket as NotifyAMPacket;
		uses interface Packet as NotifyPacket;
	*/
#ifdef SERIAL_EN
	uses interface AMSend as SerialAMSend;
	uses interface AMPacket as SerialAMPacket;
	uses interface Packet as SerialPacket;
#endif
	uses interface Timer<TMilli> as Led0Timer;
	uses interface Timer<TMilli> as Led1Timer;
	uses interface Timer<TMilli> as Led2Timer;
	uses interface Timer<TMilli> as RoutingMsgTimer;
	//uses interface Timer<TMilli> as LostTaskTimer; no tag
	
	uses interface Receive as RoutingReceive;
	//uses interface Receive as NotifyReceive; no tag
	uses interface Receive as SerialReceive;
	
	uses interface PacketQueue as RoutingSendQueue;
	uses interface PacketQueue as RoutingReceiveQueue;
	
	//uses interface PacketQueue as NotifySendQueue; no tag
	//uses interface PacketQueue as NotifyReceiveQueue; no tag

	// ADDED
	uses interface Random as Random;
	uses interface ParameterInit<uint16_t> as Seed;

	uses interface PacketQueue as AggQuerySendQueue;
	uses interface PacketQueue as AggQueryReceiveQueue;

	uses interface Packet as AggMinPacket;
	uses interface AMPacket as AggMinAMPacket;
	uses interface AMSend as AggMinAMSend;
	uses interface Receive as AggMinReceive;
	uses interface PacketQueue as AggMinSendQueue;
	uses interface PacketQueue as AggMinReceiveQueue;

	uses interface Packet as AggSumPacket;
	uses interface AMPacket as AggSumAMPacket;
	uses interface AMSend as AggSumAMSend;
	uses interface Receive as AggSumReceive;
	uses interface PacketQueue as AggSumSendQueue;
	uses interface PacketQueue as AggSumReceiveQueue;

	uses interface Packet as AggAvgPacket;
	uses interface AMPacket as AggAvgAMPacket;
	uses interface AMSend as AggAvgAMSend;
	uses interface Receive as AggAvgReceive;
	uses interface PacketQueue as AggAvgSendQueue;
	uses interface PacketQueue as AggAvgReceiveQueue;

	//phase 2
	uses interface Packet as AggMinPacketGroup;
	uses interface AMPacket as AggMinAMPacketGroup;
	uses interface AMSend as AggMinAMSendGroup;
	uses interface Receive as AggMinReceiveGroup;

	uses interface PacketQueue as QueueSendGroupMin2;
	uses interface PacketQueue as QueueReceiveGroupMin2;
	uses interface Packet as AggMinPacketGroup12;
	uses interface AMPacket as AggMinAMPacketGroup12;
	uses interface AMSend as AggMinAMSendGroup12;
	uses interface Receive as AggMinReceiveGroup12;

	uses interface Packet as AggMinPacketGroup13;
	uses interface AMPacket as AggMinAMPacketGroup13;
	uses interface AMSend as AggMinAMSendGroup13;
	uses interface Receive as AggMinReceiveGroup13;

	uses interface Packet as AggMinPacketGroup23;
	uses interface AMPacket as AggMinAMPacketGroup23;
	uses interface AMSend as AggMinAMSendGroup23;
	uses interface Receive as AggMinReceiveGroup23;

	uses interface PacketQueue as QueueSendGroupMin3;
	uses interface PacketQueue as QueueReceiveGroupMin3;
	uses interface Packet as AggMinPacketGroup123;
	uses interface AMPacket as AggMinAMPacketGroup123;
	uses interface AMSend as AggMinAMSendGroup123;
	uses interface Receive as AggMinReceiveGroup123;

	uses interface Packet as AggSumPacketGroup;
	uses interface AMPacket as AggSumAMPacketGroup;
	uses interface AMSend as AggSumAMSentGroup;
	uses interface Receive as AggSumReceiveGroup;

	uses interface PacketQueue as QueueSendGroupSum2;
	uses interface PacketQueue as QueueReceiveGroupSum2;
	uses interface Packet as AggSumPacketGroup12;
	uses interface AMPacket as AggSumAMPacketGroup12;
	uses interface AMSend as AggSumAMSendGroup12;
	uses interface Receive as AggSumReceiveGroup12;

	uses interface Packet as AggSumPacketGroup13;
	uses interface AMPacket as AggSumAMPacketGroup13;
	uses interface AMSend as AggSumAMSendGroup13;
	uses interface Receive as AggSumReceiveGroup13;

	uses interface Packet as AggSumPacketGroup23;
	uses interface AMPacket as AggSumAMPacketGroup23;
	uses interface AMSend as AggSumAMSendGroup23;
	uses interface Receive as AggSumReceiveGroup23;

	uses interface PacketQueue as QueueSendGroupSum3;
	uses interface PacketQueue as QueueReceiveGroupSum3;
	uses interface Packet as AggSumPacketGroup123;
	uses interface AMPacket as AggSumAMPacketGroup123;
	uses interface AMSend as AggSumAMSendGroup123;
	uses interface Receive as AggSumReceiveGroup123;
// END phase 2
	
	uses interface Timer<TMilli> as EpochTimer;
	// END ADDED
}
implementation
{
	uint16_t  roundCounter;
	
	message_t radioRoutingSendPkt;
	//message_t radioNotifySendPkt; no tag
	
	
	message_t serialPkt;
	//message_t serialRecPkt;
	
	bool RoutingSendBusy=FALSE;
	//bool NotifySendBusy=FALSE; no tag

#ifdef SERIAL_EN
	bool serialBusy=FALSE;
#endif
	/* no tag
		bool lostRoutingSendTask=FALSE;
		bool lostNotifySendTask=FALSE;
		bool lostRoutingRecTask=FALSE;
		bool lostNotifyRecTask=FALSE;
	*/
	uint8_t curdepth;
	uint16_t parentID;
	// ADDED
	message_t radioAggMinSendPkt;
	message_t radioAggAvgSendPkt;
	message_t radioAggSumSendPkt;
	message_t radioGroupSendPkt;
	uint8_t aggType;
	uint8_t sample;
	uint16_t epochCounter;
	uint8_t agg_min;
	uint16_t agg_sum;
	uint8_t agg_count;
	bool AvgSendBusy=FALSE;	
	bool MinSendBusy=FALSE;	
	bool SumSendBusy=FALSE;
	//END ADDED

	//ADDED Phase 2
	uint16_t agg_sum_array[3];
	uint8_t agg_min_array[3];
	//END ADDED Phase 2

	task void sendRoutingTask();
	task void receiveRoutingTask();
	task void sendAggMinTask();
	task void receiveAggMinTask();
	task void sendAggSumTask();
	task void receiveAggSumTask();
	task void sendAggAvgTask();
	task void receiveAggAvgTask();
	task void sendSumGroup12();
	task void sendSumGroup13();
	task void sendSumGroup23();
	task void sendSumGroup123();
	task void receiveSumGroup12Task();
	task void receiveSumGroup13Task();
	task void receiveSumGroup23Task();
	task void receiveSumGroup123Task();
	task void sendAggSumTaskGroup();
	task void receiveSumGroupTask();
	task void sendMinGroup12Task();
	task void sendMinGroup13Task();
	task void sendMinGroup23Task();
	task void sendMinGroup123Task();
	task void sendAggMinTaskGroup();
	task void receiveMinGroupTask();

	//no tag
	//task void sendNotifyTask();
	//task void receiveNotifyTask();
	void setAvgSendBusy(bool state){
		atomic{
		AvgSendBusy = state;
		}
	}

	void setMinSendBusy(bool state){
		atomic{
		MinSendBusy = state;
		}
	}

	void setSumSendBusy(bool state){
		atomic{
		SumSendBusy = state;
		}
	}
	/* no tag
		void setLostRoutingSendTask(bool state){
			atomic{
				lostRoutingSendTask=state;
			}
			if(state==TRUE)
			{
				//call Leds.led2On();
			}
			else 
			{
				//call Leds.led2Off();
			}
		}
		
		void setLostNotifySendTask(bool state){
			atomic{
			lostNotifySendTask=state;
			}
			
			if(state==TRUE)
			{
				//call Leds.led2On();
			}
			else 
			{
				//call Leds.led2Off();
			}
		}
		
		void setLostNotifyRecTask(bool state){
			atomic{
			lostNotifyRecTask=state;
			}
		}
		
		void setLostRoutingRecTask(bool state){
			atomic{
			lostRoutingRecTask=state;
			}
		}
	*/
	void setRoutingSendBusy(bool state){
		atomic{
			RoutingSendBusy=state;
		}
		if(state==TRUE)
		{
			call Leds.led0On();
			call Led0Timer.startOneShot(TIMER_LEDS_MILLI);
		}
		else 
		{
			//call Leds.led0Off();
		}
	}
	/* no tag
		void setNotifySendBusy(bool state){
			atomic{
			NotifySendBusy=state;
			}
			dbg("SRTreeC","NotifySendBusy = %s\n", (state == TRUE)?"TRUE":"FALSE");
		#ifdef PRINTFDBG_MODE
			printf("\t\t\t\t\t\tNotifySendBusy = %s\n", (state == TRUE)?"TRUE":"FALSE");
		#endif
			
			if(state==TRUE)
			{
				call Leds.led1On();
				call Led1Timer.startOneShot(TIMER_LEDS_MILLI);
			}
			else 
			{
				//call Leds.led1Off();
			}
		}
	*/
#ifdef SERIAL_EN
	void setSerialBusy(bool state)
	{
		serialBusy=state;
		if(state==TRUE)
		{
			call Leds.led2On();
			call Led2Timer.startOneShot(TIMER_LEDS_MILLI);
		}
		else
		{
			//call Leds.led2Off();
		}
	}
#endif
	event void Boot.booted(){
		/////// arxikopoiisi radio kai serial
		call RadioControl.start();
		call Seed.init(clock()+TOS_NODE_ID);
		
		setRoutingSendBusy(FALSE);
		setAvgSendBusy(FALSE);
		setMinSendBusy(FALSE);
		setSumSendBusy(FALSE);
		//setNotifySendBusy(FALSE); no tag
		#ifdef SERIAL_EN
		setSerialBusy(FALSE);
		#endif
		roundCounter =0;
		agg_count=0;
		agg_sum=0;
		agg_min=0xFFFF;
		sample=0;
		if(TOS_NODE_ID==0){
			#ifdef SERIAL_EN
			call SerialControl.start();
			#endif
			curdepth=0;
			parentID=0;
			epochCounter=0;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);
			#ifdef PRINTFDBG_MODE
			printf("Booted NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
			printfflush();
			#endif
		}
		else
		{
			curdepth=-1;
			parentID=-1;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);
			#ifdef PRINTFDBG_MODE
			printf("Booted NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
			printfflush();
			#endif
		}
	}
	
	event void RadioControl.startDone(error_t err){
		if (err == SUCCESS)
		{
			dbg("Radio" , "Radio initialized successfully!!!\n");
			#ifdef PRINTFDBG_MODE
			printf("Radio initialized successfully!!!\n");
			printfflush();
			#endif
			
			//call RoutingMsgTimer.startOneShot(TIMER_PERIOD_MILLI);
			//call RoutingMsgTimer.startPeriodic(TIMER_PERIOD_MILLI);
			//call LostTaskTimer.startPeriodic(SEND_CHECK_MILLIS);
			if (TOS_NODE_ID==0)
			{
				call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
				
			}
		}
		else
		{
			dbg("Radio" , "Radio initialization failed! Retrying...\n");
			#ifdef PRINTFDBG_MODE
			printf("Radio initialization failed! Retrying...\n");
			printfflush();
			#endif
			call RadioControl.start();
		}
	}
	
	event void RadioControl.stopDone(error_t err){
		dbg("Radio", "Radio stopped!\n");
		#ifdef PRINTFDBG_MODE
		printf("Radio stopped!\n");
		printfflush();
		#endif
	}
	event void SerialControl.startDone(error_t err){
		if (err == SUCCESS)
		{
			dbg("Serial" , "Serial initialized successfully! \n");
			#ifdef PRINTFDBG_MODE
			printf("Serial initialized successfully! \n");
			printfflush();
			#endif
			//call RoutingMsgTimer.startPeriodic(TIMER_PERIOD_MILLI);
		}
		else
		{
			dbg("Serial" , "Serial initialization failed! Retrying... \n");
			#ifdef PRINTFDBG_MODE
			printf("Serial initialization failed! Retrying... \n");
			printfflush();
			#endif
			call SerialControl.start();
		}
	}
	event void SerialControl.stopDone(error_t err){
		dbg("Serial", "Serial stopped! \n");
		#ifdef PRINTFDBG_MODE
		printf("Serial stopped! \n");
		printfflush();
		#endif
	}
/*	no tag
	event void LostTaskTimer.fired()
	{
		if (lostRoutingSendTask)
		{
			post sendRoutingTask();
			setLostRoutingSendTask(FALSE);
		}
		
		if( lostNotifySendTask)
		{
			post sendNotifyTask();
			setLostNotifySendTask(FALSE);
		}
		
		if (lostRoutingRecTask)
		{
			post receiveRoutingTask();
			setLostRoutingRecTask(FALSE);
		}
		
		if ( lostNotifyRecTask)
		{
			post receiveNotifyTask();
			setLostNotifyRecTask(FALSE);
		}
	}
*/
	event void RoutingMsgTimer.fired(){
		message_t tmp;
		error_t enqueueDone;
		
		RoutingMsg* mrpkt;
		dbg("Routing", "RoutingMsgTimer fired!  radioBusy = %s \n",(RoutingSendBusy)?"True":"False");
		#ifdef PRINTFDBG_MODE
		printfflush();
		printf("RoutingMsgTimer fired!  radioBusy = %s \n",(RoutingSendBusy)?"True":"False");
		printfflush();
		#endif
		if (TOS_NODE_ID==0)
		{
			roundCounter+=1;
			
			dbg("Routing", "\n ##################################### \n");
			dbg("Routing", "#######   ROUND   %u    ############## \n", roundCounter);
			dbg("Routing", "#####################################\n");
			//ADDED
			//aggType= (call Random.rand16() %5) +1; // 1=MIN,2=SUM,3=AVG
			aggType=5; // for testing only MIN
			epochCounter=0;
			agg_count=0;
			agg_sum=0;
			agg_min=0xFFFF;

			//call RoutingMsgTimer.startOneShot(LENGTH_SEASON);
		}
		
		if(call RoutingSendQueue.full())
		{
			#ifdef PRINTFDBG_MODE
			printf("RoutingSendQueue is FULL!!! \n");
			printfflush();
			#endif
			return;
		}
		
		
		mrpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&tmp, sizeof(RoutingMsg)));
		if(mrpkt==NULL)
		{
			dbg("Routing","RoutingMsgTimer.fired(): No valid payload... \n");
			#ifdef PRINTFDBG_MODE
			printf("RoutingMsgTimer.fired(): No valid payload... \n");
			printfflush();
			#endif
			return;
		}
		atomic{
			mrpkt->depth = curdepth;
			mrpkt->aggType=aggType; // ADDED
		}
		dbg("Routing" , "Sending RoutingMsg... \n");

		#ifdef PRINTFDBG_MODE
		printf("NodeID= %d : RoutingMsg sending...!!!! \n", TOS_NODE_ID);
		printfflush();
		#endif		
		call RoutingAMPacket.setDestination(&tmp, AM_BROADCAST_ADDR);
		call RoutingPacket.setPayloadLength(&tmp, sizeof(RoutingMsg));
		
		enqueueDone=call RoutingSendQueue.enqueue(tmp);
		
		if( enqueueDone==SUCCESS)
		{
			if (call RoutingSendQueue.size()==1)
			{
				dbg("Routing", "SendTask() posted!!\n");
				#ifdef PRINTFDBG_MODE
				printf("SendTask() posted!!\n");
				printfflush();
				#endif
				post sendRoutingTask();
			}
			
			dbg("Routing","RoutingMsg enqueued successfully in SendingQueue!!!\n");
			#ifdef PRINTFDBG_MODE
			printf("RoutingMsg enqueued successfully in SendingQueue!!!\n");
			printfflush();
			#endif
		}
		else
		{
			dbg("Routing","RoutingMsg failed to be enqueued in SendingQueue!!!");
			#ifdef PRINTFDBG_MODE			
			printf("RoutingMsg failed to be enqueued in SendingQueue!!!\n");
			printfflush();
			#endif
		}		
	}
	
	event void Led0Timer.fired(){
		call Leds.led0Off();
	}
	event void Led1Timer.fired(){
		call Leds.led1Off();
	}
	event void Led2Timer.fired(){
		call Leds.led2Off();
	}
	
	event void RoutingAMSend.sendDone(message_t * msg , error_t err){
		dbg("Routing", "A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");
		#ifdef PRINTFDBG_MODE
		printf("A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");
		printfflush();
		#endif
		
		dbg("Routing" , "Package sent %s \n", (err==SUCCESS)?"True":"False");
		#ifdef PRINTFDBG_MODE
		printf("Package sent %s \n", (err==SUCCESS)?"True":"False");
		printfflush();
		#endif
		setRoutingSendBusy(FALSE);
		
		if(!(call RoutingSendQueue.empty()))
		{
			post sendRoutingTask();
		}
		//call Leds.led0Off();
	
	}
/*	no tag
	event void NotifyAMSend.sendDone(message_t *msg , error_t err)
	{
		dbg("SRTreeC", "A Notify package sent... %s \n",(err==SUCCESS)?"True":"False");
	#ifdef PRINTFDBG_MODE
		printf("A Notify package sent... %s \n",(err==SUCCESS)?"True":"False");
		printfflush();
	#endif
		
	
		dbg("SRTreeC" , "Package sent %s \n", (err==SUCCESS)?"True":"False");
	#ifdef PRINTFDBG_MODE
		printf("Package sent %s \n", (err==SUCCESS)?"True":"False");
		printfflush();
	#endif
		setNotifySendBusy(FALSE);
		
		if(!(call NotifySendQueue.empty()))
		{
			post sendNotifyTask();
		}
		//call Leds.led0Off();
		
		
	}
	
*/
	event void SerialAMSend.sendDone(message_t* msg , error_t err){
		if ( &serialPkt == msg)
		{
			dbg("Serial" , "Package sent %s \n", (err==SUCCESS)?"True":"False");
			#ifdef PRINTFDBG_MODE
			printf("Package sent %s \n", (err==SUCCESS)?"True":"False");
			printfflush();
			#endif
			setSerialBusy(FALSE);
			
			//call Leds.led2Off();
		}
	}
/* no tag NotifyReceive
	event message_t* NotifyReceive.receive( message_t* msg , void* payload , uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;
		
		msource = call NotifyAMPacket.source(msg);
		
		dbg("SRTreeC", "### NotifyReceive.receive() start ##### \n");
		dbg("SRTreeC", "Something received!!!  from %u   %u \n",((NotifyParentMsg*) payload)->senderID, msource);
		#ifdef PRINTFDBG_MODE		
		printf("Something Received!!!, len = %u , npm=%u , rm=%u\n",len, sizeof(NotifyParentMsg), sizeof(RoutingMsg));
		printfflush();
		#endif

		//if(len!=sizeof(NotifyParentMsg))
		//{
			//dbg("SRTreeC","\t\tUnknown message received!!!\n");
		#ifdef PRINTFDBG_MODE
			//printf("\t\t Unknown message received!!!\n");
			//printfflush();
		#endif
			//return msg;http://courses.ece.tuc.gr/
		//}
		
		//call Leds.led1On();
		//call Led1Timer.startOneShot(TIMER_LEDS_MILLI);
		atomic{
		memcpy(&tmp,msg,sizeof(message_t));
		//tmp=*(message_t*)msg;
		}
		enqueueDone=call NotifyReceiveQueue.enqueue(tmp);
		
		if( enqueueDone== SUCCESS)
		{
		#ifdef PRINTFDBG_MODE
			printf("posting receiveNotifyTask()!!!! \n");
			printfflush();
		#endif
			post receiveNotifyTask();
		}
		else
		{
			dbg("SRTreeC","NotifyMsg enqueue failed!!! \n");
			#ifdef PRINTFDBG_MODE
			printf("NotifyMsg enqueue failed!!! \n");
			printfflush();
			#endif			
		}
		
		//call Leds.led1Off();
		dbg("SRTreeC", "### NotifyReceive.receive() end ##### \n");
		return msg;
	}
*/
//	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
	event message_t* RoutingReceive.receive( message_t * msg , void * payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;
		
		msource =call RoutingAMPacket.source(msg);
		
		dbg("Routing", "### RoutingReceive.receive() start ##### \n");
		dbg("Routing", "Something received!!!  from %u\n",  msource);
		//dbg("SRTreeC", "Something received!!!\n");
		#ifdef PRINTFDBG_MODE		
		printf("Something Received!!!, len = %u , npm=%u , rm=%u\n",len, sizeof(NotifyParentMsg), sizeof(RoutingMsg));
		printfflush();
		#endif
		//call Leds.led1On();
		//call Led1Timer.startOneShot(TIMER_LEDS_MILLI);
		
		//if(len!=sizeof(RoutingMsg))
		//{
			//dbg("SRTreeC","\t\tUnknown message received!!!\n");
		//#ifdef PRINTFDBG_MODE
			//printf("\t\t Unknown message received!!!\n");
			//printfflush();
        //#endif
			//return msg;
		//}
		
		atomic{
		memcpy(&tmp,msg,sizeof(message_t));
		//tmp=*(message_t*)msg;
		}
		enqueueDone=call RoutingReceiveQueue.enqueue(tmp);
		if(enqueueDone == SUCCESS)
		{
			#ifdef PRINTFDBG_MODE
			printf("posting receiveRoutingTask()!!!! \n");
			printfflush();
			#endif
			post receiveRoutingTask();
		}
		else
		{
			dbg("Routing","RoutingMsg enqueue failed!!! \n");
			#ifdef PRINTFDBG_MODE
			printf("RoutingMsg enqueue failed!!! \n");
			printfflush();
			#endif			
		}
		
		//call Leds.led1Off();
		
		dbg("Routing", "### RoutingReceive.receive() end ##### \n");
		return msg;
	}
	
	event message_t* SerialReceive.receive(message_t* msg , void* payload , uint8_t len){
		// when receiving from serial port
		dbg("Serial","Received msg from serial port \n");
		#ifdef PRINTFDBG_MODE
		printf("Reveived message from serial port \n");
		printfflush();
		#endif
		return msg;
	}
	
	////////////// Tasks implementations //////////////////////////////
	
	
	task void sendRoutingTask(){
		//uint8_t skip;
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;
		//message_t radioRoutingSendPkt;
		
		#ifdef PRINTFDBG_MODE
		printf("SendRoutingTask(): Starting....\n");
		printfflush();
		#endif
		if (call RoutingSendQueue.empty())
		{
			dbg("Routing","sendRoutingTask(): Q is empty!\n");
			#ifdef PRINTFDBG_MODE		
			printf("sendRoutingTask():Q is empty!\n");
			printfflush();
			#endif
			return;
		}
		
		
		if(RoutingSendBusy){
			dbg("Routing","sendRoutingTask(): RoutingSendBusy= TRUE!!!\n");
			#ifdef PRINTFDBG_MODE
			printf(	"sendRoutingTask(): RoutingSendBusy= TRUE!!!\n");
			printfflush();
			#endif
			//setLostRoutingSendTask(TRUE);
			return;
		}
		if (curdepth >= 0) {
			uint8_t random_offset = call Random.rand16() % 10;
			dbg("Epoch","Start epoch timer for node %d \n", TOS_NODE_ID);
			call EpochTimer.startPeriodicAt(-(curdepth*WINDOW_MILLI)+random_offset,EPOCH_PERIOD_MILLI);
		}
		
		radioRoutingSendPkt = call RoutingSendQueue.dequeue();
		
		//call Leds.led2On();
		//call Led2Timer.startOneShot(TIMER_LEDS_MILLI);
		mlen= call RoutingPacket.payloadLength(&radioRoutingSendPkt);
		mdest=call RoutingAMPacket.destination(&radioRoutingSendPkt);
		if(mlen!=sizeof(RoutingMsg))
		{
			dbg("Routing","\t\tsendRoutingTask(): Unknown message!!!\n");
			#ifdef PRINTFDBG_MODE
			printf("\t\tsendRoutingTask(): Unknown message!!!!\n");
			printfflush();
			#endif
			return;
		}
		sendDone=call RoutingAMSend.send(mdest,&radioRoutingSendPkt,mlen);
		
		if ( sendDone== SUCCESS)
		{
			dbg("Routing","sendRoutingTask(): Send returned success!!!\n");
			#ifdef PRINTFDBG_MODE
			printf("sendRoutingTask(): Send returned success!!!\n");
			printfflush();
			#endif
			setRoutingSendBusy(TRUE);
		}
		else
		{
			dbg("Routing","send failed!!!\n");
			#ifdef PRINTFDBG_MODE
			printf("SendRoutingTask(): send failed!!!\n");
			printfflush();
			#endif
			//setRoutingSendBusy(FALSE);
		}
	}
	/**
	 * dequeues a message and sends it
	 */
/* no tag
	task void sendNotifyTask(){
		uint8_t mlen;//, skip;
		error_t sendDone;
		uint16_t mdest;
		NotifyParentMsg* mpayload;
		
		//message_t radioNotifySendPkt;
		
		#ifdef PRINTFDBG_MODE
		printf("SendNotifyTask(): going to send one more package.\n");
		printfflush();
		#endif
		if (call NotifySendQueue.empty())
		{
			dbg("SRTreeC","sendNotifyTask(): Q is empty!\n");
			#ifdef PRINTFDBG_MODE		
			printf("sendNotifyTask():Q is empty!\n");
			printfflush();
			#endif
			return;
		}
		
		if(NotifySendBusy==TRUE)
		{
			dbg("SRTreeC","sendNotifyTask(): NotifySendBusy= TRUE!!!\n");
			#ifdef PRINTFDBG_MODE
			printf(	"sendTask(): NotifySendBusy= TRUE!!!\n");
			printfflush();
			#endif
			setLostNotifySendTask(TRUE);
			return;
		}
		
		radioNotifySendPkt = call NotifySendQueue.dequeue();
		
		//call Leds.led2On();
		//call Led2Timer.startOneShot(TIMER_LEDS_MILLI);
		mlen=call NotifyPacket.payloadLength(&radioNotifySendPkt);
		
		mpayload= call NotifyPacket.getPayload(&radioNotifySendPkt,mlen);
		
		if(mlen!= sizeof(NotifyParentMsg))
		{
			dbg("SRTreeC", "\t\t sendNotifyTask(): Unknown message!!\n");
			#ifdef PRINTFDBG_MODE
			printf("\t\t sendNotifyTask(): Unknown message!!\n");
			printfflush();
			#endif
			return;
		}
		
		dbg("SRTreeC" , " sendNotifyTask(): mlen = %u  senderID= %u \n",mlen,mpayload->senderID);
		#ifdef PRINTFDBG_MODE
		printf("\t\t\t\t sendNotifyTask(): mlen=%u\n",mlen);
		printfflush();
		#endif
		mdest= call NotifyAMPacket.destination(&radioNotifySendPkt);
		
		
		sendDone=call NotifyAMSend.send(mdest,&radioNotifySendPkt, mlen);
		
		if ( sendDone== SUCCESS)
		{
			dbg("Routing","sendNotifyTask(): Send returned success!!!\n");
			#ifdef PRINTFDBG_MODE
			printf("sendNotifyTask(): Send returned success!!!\n");
			printfflush();
			#endif
			setNotifySendBusy(TRUE);
		}
		else
		{
			dbg("SRTreeC","send failed!!!\n");
			#ifdef PRINTFDBG_MODE
			printf("SendNotifyTask(): send failed!!!\n");
			#endif
			//setNotifySendBusy(FALSE);
		}
	}
*/
	////////////////////////////////////////////////////////////////////
		//*****************************************************************/
	///////////////////////////////////////////////////////////////////
	/**
	 * dequeues a message and processes it
	 */
	
	task void receiveRoutingTask(){
		message_t tmp;
		uint8_t len;
		message_t radioRoutingRecPkt;
		
		#ifdef PRINTFDBG_MODE
		printf("ReceiveRoutingTask():received msg...\n");
		printfflush();
		#endif
		radioRoutingRecPkt= call RoutingReceiveQueue.dequeue();
		
		len= call RoutingPacket.payloadLength(&radioRoutingRecPkt);
		
		dbg("Routing","ReceiveRoutingTask(): len=%u \n",len);
		#ifdef PRINTFDBG_MODE
		printf("ReceiveRoutingTask(): len=%u!\n",len);
		printfflush();
		#endif
		// processing of radioRecPkt
		
		if(len == sizeof(RoutingMsg))
		{
			RoutingMsg * mpkt = (RoutingMsg*) (call RoutingPacket.getPayload(&radioRoutingRecPkt,len));
			if(mpkt==NULL)
			{
				dbg("Routing","receiveRoutingTask(): No valid payload... \n");
				return;
			}
			//if(TOS_NODE_ID >0)
			//{
				//call RoutingMsgTimer.startOneShot(TIMER_PERIOD_MILLI);
			//}
			//
			
			dbg("Routing" , "receiveRoutingTask(): depth= %d \n", mpkt->depth);
			#ifdef PRINTFDBG_MODE
			printf("NodeID= %d , RoutingMsg received! \n",TOS_NODE_ID);
			printf("receiveRoutingTask(): depth= %d \n", mpkt->depth);
			printfflush();
			#endif
			if ( (parentID<0)||(parentID>=65535))
			{
				// tote den exei akoma patera
				parentID= call RoutingAMPacket.source(&radioRoutingRecPkt);//mpkt->senderID;q
				curdepth= mpkt->depth + 1;
				aggType = mpkt->aggType;
				epochCounter=0;
				agg_count=0;
				agg_sum=0;
				agg_min=0xFFFF;
				if (TOS_NODE_ID != 0){ 
					call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
				}
				dbg("printTopology", "NodeID %d: parentID= %d , curdepth= %d , aggType= %d \n", TOS_NODE_ID, parentID, curdepth, aggType);
				#ifdef PRINTFDBG_MODE
				printf("NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
				printfflush();
				#endif
			}
		}
	/* no tag
				m = (NotifyParentMsg *) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyParentMsg)));
				m->senderID=TOS_NODE_ID;
				m->depth = curdepth;
				m->parentID = parentID;
				dbg("SRTreeC" , "receiveRoutingTask():NotifyParentMsg sending to node= %d... \n", parentID);
				#ifdef PRINTFDBG_MODE
				printf("NotifyParentMsg NodeID= %d sent!!! \n", TOS_NODE_ID);
				printfflush();
				#endif
				call NotifyAMPacket.setDestination(&tmp, parentID);
				call NotifyPacket.setPayloadLength(&tmp,sizeof(NotifyParentMsg));
				
				if (call NotifySendQueue.enqueue(tmp)==SUCCESS)
				{
					dbg("SRTreeC", "receiveRoutingTask(): NotifyParentMsg enqueued in SendingQueue successfully!!!");
					#ifdef PRINTFDBG_MODE
					printf("receiveRoutingTask(): NotifyParentMsg enqueued successfully!!!");
					printfflush();
					#endif
					if (call NotifySendQueue.size() == 1)
					{
						post sendNotifyTask();
					}
				}
				if (TOS_NODE_ID!=0)
				{
					call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
				}
			}
			else
			{
				
				if (( curdepth > mpkt->depth +1) || (mpkt->senderID==parentID))
				{
					uint16_t oldparentID = parentID;
					
				
					parentID= call RoutingAMPacket.source(&radioRoutingRecPkt);//mpkt->senderID;
					curdepth = mpkt->depth + 1;
				
					#ifdef PRINTFDBG_MODE
					printf("NodeID= %d : curdepth= %d , parentID= %d \n", TOS_NODE_ID ,curdepth , parentID);
					printfflush();
					#endif					
									
					
					dbg("SRTreeC" , "NotifyParentMsg sending to node= %d... \n", oldparentID);
					#ifdef PRINTFDBG_MODE
					printf("NotifyParentMsg sending to node=%d... \n", oldparentID);
					printfflush();
					#endif
					if ( (oldparentID<65535) || (oldparentID>0) || (oldparentID==parentID))
					{
						m = (NotifyParentMsg *) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyParentMsg)));
						m->senderID=TOS_NODE_ID;
						m->depth = curdepth;
						m->parentID = parentID;
						
						call NotifyAMPacket.setDestination(&tmp,oldparentID);
						//call NotifyAMPacket.setType(&tmp,AM_NOTIFYPARENTMSG);
						call NotifyPacket.setPayloadLength(&tmp,sizeof(NotifyParentMsg));
								
						if (call NotifySendQueue.enqueue(tmp)==SUCCESS)
						{
							dbg("SRTreeC", "receiveRoutingTask(): NotifyParentMsg enqueued in SendingQueue successfully!!!\n");
							#ifdef PRINTFDBG_MODE
							printf("receiveRoutingTask(): NotifyParentMsg enqueued successfully!!!");
							printfflush();
							#endif
							if (call NotifySendQueue.size() == 1)
							{
								post sendNotifyTask();
							}
						}
					}
					if (TOS_NODE_ID!=0)
					{
						call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
					}
					// tha stelnei kai ena minima NotifyParentMsg 
					// ston kainourio patera kai ston palio patera.
					
					if (oldparentID!=parentID)
					{
						m = (NotifyParentMsg *) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyParentMsg)));
						m->senderID=TOS_NODE_ID;
						m->depth = curdepth;
						m->parentID = parentID;
						dbg("SRTreeC" , "receiveRoutingTask():NotifyParentMsg sending to node= %d... \n", parentID);
						#ifdef PRINTFDBG_MODE
						printf("NotifyParentMsg NodeID= %d sent!!! \n", TOS_NODE_ID);
						printfflush();
						#endif
						call NotifyAMPacket.setDestination(&tmp, parentID);
						call NotifyPacket.setPayloadLength(&tmp,sizeof(NotifyParentMsg));
						
						if (call NotifySendQueue.enqueue(tmp)==SUCCESS)
						{
							dbg("SRTreeC", "receiveRoutingTask(): NotifyParentMsg enqueued in SendingQueue successfully!!! \n");
							#ifdef PRINTFDBG_MODE					
							printf("receiveRoutingTask(): NotifyParentMsg enqueued successfully!!!");
							printfflush();
							#endif
							if (call NotifySendQueue.size() == 1)
							{
								post sendNotifyTask();
							}
						}
					}
				}
				
				
			}
		}
		else
		{
			dbg("SRTreeC","receiveRoutingTask():Empty message!!! \n");
			#ifdef PRINTFDBG_MODE
			printf("receiveRoutingTask():Empty message!!! \n");
			printfflush();
			#endif
			setLostRoutingRecTask(TRUE);
			return;
		}
		*/
	}

	
/* no tag
	task void receiveNotifyTask()
	{
		message_t tmp;
		uint8_t len;
		message_t radioNotifyRecPkt;
		
		#ifdef PRINTFDBG_MODE
		printf("ReceiveNotifyTask():received msg...\n");
		printfflush();
		#endif
		radioNotifyRecPkt= call NotifyReceiveQueue.dequeue();
		
		len= call NotifyPacket.payloadLength(&radioNotifyRecPkt);
		
		dbg("SRTreeC","ReceiveNotifyTask(): len=%u \n",len);
		#ifdef PRINTFDBG_MODE
		printf("ReceiveNotifyTask(): len=%u!\n",len);
		printfflush();
		#endif
		if(len == sizeof(NotifyParentMsg))
		{
			// an to parentID== TOS_NODE_ID tote
			// tha proothei to minima pros tin riza xoris broadcast
			// kai tha ananeonei ton tyxon pinaka paidion..
			// allios tha diagrafei to paidi apo ton pinaka paidion
			
			NotifyParentMsg* mr = (NotifyParentMsg*) (call NotifyPacket.getPayload(&radioNotifyRecPkt,len));
			
			dbg("SRTreeC" , "NotifyParentMsg received from %d !!! \n", mr->senderID);
			#ifdef PRINTFDBG_MODE
			printf("NodeID= %d NotifyParentMsg from senderID = %d!!! \n",TOS_NODE_ID , mr->senderID);
			printfflush();
			#endif
			if ( mr->parentID == TOS_NODE_ID)
			{
				// tote prosthiki stin lista ton paidion.
				
			}
			else
			{
				// apla diagrafei ton komvo apo paidi tou..
				
			}
			if ( TOS_NODE_ID==0)
			{
				#ifdef SERIAL_EN
				if (!serialBusy)
				{ // mipos mporei na mpei san task?
					NotifyParentMsg * m = (NotifyParentMsg *) (call SerialPacket.getPayload(&serialPkt, sizeof(NotifyParentMsg)));
					m->senderID=mr->senderID;
					m->depth = mr->depth;
					m->parentID = mr->parentID;
					dbg("Serial", "Sending NotifyParentMsg to PC... \n");
					#ifdef PRINTFDBG_MODE
					printf("Sending NotifyParentMsg to PC..\n");
					printfflush();
					#endif
					if (call SerialAMSend.send(parentID, &serialPkt, sizeof(NotifyParentMsg))==SUCCESS)
					{
						setSerialBusy(TRUE);
					}
				}
			#endif
			}
			else
			{
				NotifyParentMsg* m;
				memcpy(&tmp,&radioNotifyRecPkt,sizeof(message_t));
				
				m = (NotifyParentMsg *) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyParentMsg)));
				//m->senderID=mr->senderID;
				//m->depth = mr->depth;
				//m->parentID = mr->parentID;
				
				dbg("SRTreeC" , "Forwarding NotifyParentMsg from senderID= %d  to parentID=%d \n" , m->senderID, parentID);
				#ifdef PRINTFDBG_MODE
				printf("NotifyParentMsg NodeID= %d sent!\n", TOS_NODE_ID);
				printfflush();
				#endif
				call NotifyAMPacket.setDestination(&tmp, parentID);
				call NotifyPacket.setPayloadLength(&tmp,sizeof(NotifyParentMsg));
				
				if (call NotifySendQueue.enqueue(tmp)==SUCCESS)
				{
					dbg("SRTreeC", "receiveNotifyTask(): NotifyParentMsg enqueued in SendingQueue successfully!!!\n");
					if (call NotifySendQueue.size() == 1)
					{
						post sendNotifyTask();
					}
				}

				
			}
			
		}
		else
		{
			dbg("SRTreeC","receiveNotifyTask():Empty message!!! \n");
			#ifdef PRINTFDBG_MODE
			printf("receiveNotifyTask():Empty message!!! \n");
			printfflush();
			#endif
			setLostNotifyRecTask(TRUE);
			return;
		}
		
	}
*/
	
	//ADDED
	event void EpochTimer.fired(){
		message_t tmp;
		uint8_t temp;
		error_t enqueueDone;

		dbg("Epoch","EpochTimer fired! \n");

		epochCounter+=1;
		if(epochCounter==1){
			sample = (call Random.rand16() % 60) + 1; // random sample between 1 and 60
		}else{
			sample = (sample * ((call Random.rand16() % 40) + 80)) / 100; // * 0.8 to 1.2
			if(sample > 60){
				sample = 60;
			}else if(sample < 1){
				sample = 1;
			}
		}
		
		if(aggType==AGGREGATION_TYPE_MIN){
			dbg("Sample","NodeID= %d : AggregationMin sample= %u , agg_min= %u \n", TOS_NODE_ID, sample, agg_min);
			if(sample < agg_min){
				temp = sample;
				agg_min = sample;
			}else{
				temp = agg_min;
			}
			
			if(TOS_NODE_ID==0){
				dbg("Results","***////////||||||\\\\\\***\n");
				dbg("Results","AGG RESULT epoch=%u MIN=%u \n", epochCounter, agg_min);
				dbg("Results","***\\\\\\\\||||||//////***\n");
			}else{
				AggregationMin* msgMin;
				if(call AggMinSendQueue.full()){
					dbg("Min","AggMinSendQueue is FULL!!! \n");
					return;
				}
				msgMin = (AggregationMin*) (call AggMinPacket.getPayload(&tmp, sizeof(AggregationMin)));
				if(msgMin==NULL){
					dbg("Min","EpochTimer.fired(): No valid payload... \n");
					return;
				}
				atomic{
				msgMin->minVal = agg_min;
				//msgMin->epoch = epochCounter;
				}
				dbg("Min","NodeID= %d : AggregationMin value= %u \n", TOS_NODE_ID, agg_min);
				call AggMinAMPacket.setDestination(&tmp, parentID);
				call AggMinPacket.setPayloadLength(&tmp, sizeof(AggregationMin));
				enqueueDone = call AggMinSendQueue.enqueue(tmp);

				if(enqueueDone==SUCCESS){
					if(call AggMinSendQueue.size()==1){
						dbg("Min","SendAggMinTask() posted!!\n");
						post sendAggMinTask();
					}
					dbg("Min","AggregationMin enqueued successfully in SendingQueue!!!\n");
				}
			}//if for TOS_NODE_ID==0	
		}else if(aggType==AGGREGATION_TYPE_SUM){
			dbg("Sample","NodeID= %d : AggregationSum sample= %u , sumBefore= %u \n", TOS_NODE_ID, sample, agg_sum);
			agg_sum += sample;
			dbg("Sample","NodeID= %d : AggregationSum sumAfter= %u \n", TOS_NODE_ID, agg_sum);
			if(TOS_NODE_ID==0){
				
				dbg("Results","***////////||||||\\\\\\***\n");
				dbg("Results","AGG RESULT epoch=%u Sum=%u \n", epochCounter, agg_sum);
				dbg("Results","***\\\\\\\\||||||//////***\n");
			}else{
				AggregationSum* msgSum;
				if(call AggSumSendQueue.full()){
					dbg("Sum","AggSumSendQueue is FULL!!! \n");
					return;
				}
				msgSum = (AggregationSum*) (call AggSumPacket.getPayload(&tmp, sizeof(AggregationSum)));
				if(msgSum==NULL){
					dbg("Sum","EpochTimer.fired(): No valid payload... \n");
					return;
				}
				atomic{
				msgSum->sum = agg_sum;
				//msgSum->epoch = epochCounter;
				}
				dbg("Sum","NodeID= %d : AggregationSum value= %u \n", TOS_NODE_ID, agg_sum);
				call AggSumAMPacket.setDestination(&tmp, parentID);
				call AggSumPacket.setPayloadLength(&tmp, sizeof(AggregationSum));
				enqueueDone = call AggSumSendQueue.enqueue(tmp);

				if(enqueueDone==SUCCESS){
					if(call AggSumSendQueue.size()==1){
						dbg("Sum","SendAggSumTask() posted!!\n");
						post sendAggSumTask();
					}
					dbg("Sum","AggregationSum enqueued successfully in SendingQueue!!!\n");
				}
			}//if for TOS_NODE_ID==0
		}else if(aggType==AGGREGATION_TYPE_AVG){
			dbg("Sample","NodeID= %d : AggregationAvg sample= %u , BeforeCount= %u, BeforeSum= %u \n", TOS_NODE_ID, sample, agg_count, agg_sum);
			agg_sum += sample;
			agg_count += 1;
			dbg("Sample","NodeID= %d : AggregationAvg CountAfter = %u, SumAfter= %u \n", TOS_NODE_ID, agg_count, agg_sum);
			if(TOS_NODE_ID==0){
				dbg("Results","***////////||||||\\\\\\***\n");
				dbg("Results","AGG RESULT epoch=%u AVG=%u/%u=%u \n", epochCounter, agg_sum, agg_count, agg_sum/agg_count);
				dbg("Results","***\\\\\\\\||||||//////***\n");
				}else{
				AggregationAvg* msgAvg;
				if(call AggAvgSendQueue.full()){
					dbg("Avg","AggAvgSendQueue is FULL!!! \n");
					return;
				}
				msgAvg = (AggregationAvg*) (call AggAvgPacket.getPayload(&tmp, sizeof(AggregationAvg)));
				if(msgAvg==NULL){
					dbg("Avg","EpochTimer.fired(): No valid payload... \n");
					return;
				}
				atomic{
				msgAvg->sum = agg_sum;
				msgAvg->count = agg_count;
				//msgAvg->epoch = epochCounter;
				}
				dbg("Avg","NodeID= %d : AggregationAvg value= %u/%u \n", TOS_NODE_ID, agg_sum, agg_count);
				call AggAvgAMPacket.setDestination(&tmp, parentID);
				call AggAvgPacket.setPayloadLength(&tmp, sizeof(AggregationAvg));
				enqueueDone = call AggAvgSendQueue.enqueue(tmp);

				if(enqueueDone==SUCCESS){
					if(call AggAvgSendQueue.size()==1){
						dbg("Avg","SendAggAvgTask() posted!!\n");
						post sendAggAvgTask();
					}
					dbg("Avg","AggregationAvg enqueued successfully in SendingQueue!!!\n");
				}
			}//if for TOS_NODE_ID==0
		}else if(aggType==AGGREGATION_TYPE_MIN_GROUP){
			uint8_t groupid = TOS_NODE_ID % 3;
			dbg("Sample","NodeID %d Group %u AggregationMin sample %u, %u\n", TOS_NODE_ID, groupid+1, sample, agg_min_array[groupid]);
			if(sample < agg_min_array[groupid]){
				agg_min_array[groupid] = sample;
			}
			dbg("Sample","NodeID %d Group %u AggregationMin minAfter %u\n", TOS_NODE_ID, groupid+1, agg_min_array[groupid]);

			if(TOS_NODE_ID == 0) {
				uint8_t i;
				dbg("Results","***////////||||||\\\\\\***\n");
				for(i=0; i<3; i++) {
					dbg("Results","AGG RESULT epoch%u Group %u MIN%u\n", epochCounter, i+1, agg_min_array[i]);
				}
				dbg("Results","***\\\\\\\\||||||//////***\n");
			} else {
				bool toSendForGroup1 = agg_min_array[0] != 0xFF;
				bool toSendForGroup2 = agg_min_array[1] != 0xFF;
				bool toSendForGroup3 = agg_min_array[2] != 0xFF;
		
				if(toSendForGroup1 && toSendForGroup2 && toSendForGroup3) {
					Min3Group* msgMin123;
					if(call QueueSendGroupMin3.full()) {
						dbg("Min","QueueSendGroupMin3 is FULL!!!\n");
						return;
					}
					msgMin123 = (Min3Group*)call AggMinPacketGroup123.getPayload(&tmp, sizeof(Min3Group));
					if(msgMin123 == NULL) {
						dbg("Min","EpochTimer.fired No valid payload...\n");
						return;
					}
					atomic {
					msgMin123->minGroup1 = agg_min_array[0];
					msgMin123->minGroup2 = agg_min_array[1];
					msgMin123->minGroup3 = agg_min_array[2];
					}
					dbg("Min","NodeID %d AggregationMin Group1%u, Group2%u, Group3%u\n", TOS_NODE_ID, agg_min_array[0], agg_min_array[1], agg_min_array[2]);
					call AggMinAMPacketGroup123.setDestination(&tmp, parentID);
					call AggMinPacketGroup123.setPayloadLength(&tmp, sizeof(Min3Group));
					enqueueDone = call QueueSendGroupMin3.enqueue(tmp);
					if(enqueueDone == SUCCESS) {
						if(call QueueSendGroupMin3.size() == 1) {
							dbg("Min","sendMinGroup123 posted!!\n");
							post sendMinGroup123Task();
						}
						dbg("Min","AggregationMin Group1,2,3 enqueued successfully in SendingQueue!!!\n");
					}
				} else if(toSendForGroup1 && toSendForGroup2) {
					Min12Group* msgMin12;
					if(call QueueSendGroupMin2.full()) {
						dbg("Min","QueueSendGroupMin2 is FULL!!!\n");
						return;
					}
					msgMin12 = (Min12Group*)call AggMinPacketGroup12.getPayload(&tmp, sizeof(Min12Group));
					if(msgMin12 == NULL) {
						dbg("Min","EpochTimer.fired No valid payload...\n");
						return;
					}
					atomic {
					msgMin12->minGroup1 = agg_min_array[0];
					msgMin12->minGroup2 = agg_min_array[1];
					}
					dbg("Min","NodeID %d AggregationMin Group1%u, Group2%u\n", TOS_NODE_ID, agg_min_array[0], agg_min_array[1]);
					call AggMinAMPacketGroup12.setDestination(&tmp, parentID);
					call AggMinPacketGroup12.setPayloadLength(&tmp, sizeof(Min12Group));
					enqueueDone = call QueueSendGroupMin2.enqueue(tmp);
					if(enqueueDone == SUCCESS) {
						if(call QueueSendGroupMin2.size() == 1) {
							dbg("Min","sendMinGroup12 posted!!\n");
							post sendMinGroup12Task();
						}
					dbg("Min","AggregationMin Group1,2 enqueued successfully in SendingQueue!!!\n");
					}
				} else if(toSendForGroup1 && toSendForGroup3) {
					Min13Group* msgMin13;
					if(call QueueSendGroupMin2.full()) {
						dbg("Min","QueueSendGroupMin2 is FULL!!!\n");
						return;
					}
					msgMin13 = (Min13Group*)call AggMinPacketGroup13.getPayload(&tmp, sizeof(Min13Group));
					if(msgMin13 == NULL) {
						dbg("Min","EpochTimer.fired No valid payload...\n");
						return;
					}
					atomic {
					msgMin13->minGroup1 = agg_min_array[0];
					msgMin13->minGroup3 = agg_min_array[2];
					}
					dbg("Min","NodeID %d AggregationMin Group1%u, Group3%u\n", TOS_NODE_ID, agg_min_array[0], agg_min_array[2]);
					call AggMinAMPacketGroup13.setDestination(&tmp, parentID);
					call AggMinPacketGroup13.setPayloadLength(&tmp, sizeof(Min13Group));
					enqueueDone = call QueueSendGroupMin2.enqueue(tmp);
					if(enqueueDone == SUCCESS) {
						if(call QueueSendGroupMin2.size() == 1) {
						dbg("Min","sendMinGroup13 posted!!\n");
						post sendMinGroup13Task();
					}
					dbg("Min","AggregationMin Group1,3 enqueued successfully in SendingQueue!!!\n");
					}
				} else if(toSendForGroup2 && toSendForGroup3) {
					Min23Group* msgMin23;
					if(call QueueSendGroupMin2.full()) {
						dbg("Min","QueueSendGroupMin2 is FULL!!!\n");
						return;
					}
					msgMin23 = (Min23Group*)call AggMinPacketGroup23.getPayload(&tmp, sizeof(Min23Group));
					if(msgMin23 == NULL) {
					dbg("Min","EpochTimer.fired No valid payload...\n");
					return;
					}
					atomic {
					msgMin23->minGroup2 = agg_min_array[1];
					msgMin23->minGroup3 = agg_min_array[2];
					}
					dbg("Min","NodeID %d AggregationMin Group2%u, Group3%u\n", TOS_NODE_ID, agg_min_array[1], agg_min_array[2]);
					call AggMinAMPacketGroup23.setDestination(&tmp, parentID);
					call AggMinPacketGroup23.setPayloadLength(&tmp, sizeof(Min23Group));
					enqueueDone = call QueueSendGroupMin2.enqueue(tmp);
					if(enqueueDone == SUCCESS) {
						if(call QueueSendGroupMin2.size() == 1) {
							dbg("Min","sendMinGroup23 posted!!\n");
							post sendMinGroup23Task();
						}
					dbg("Min","AggregationMin Group2,3 enqueued successfully in SendingQueue!!!\n");
					}
				} else if(toSendForGroup1 || toSendForGroup2 || toSendForGroup3) {
				AggregationMin* msgMin;
				if(call AggMinSendQueue.full()) {
					dbg("Min","AggMinSendQueue is FULL!!!\n");
					return;
				}
				msgMin = (AggregationMin*)call AggMinPacket.getPayload(&tmp, sizeof(AggregationMin));
				if(msgMin == NULL) {
					dbg("Min","EpochTimer.fired No valid payload...\n");
					return;
				}
				atomic {
				if(toSendForGroup1) msgMin->minVal = agg_min_array[0];
				else if(toSendForGroup2) msgMin->minVal = agg_min_array[1];
				else msgMin->minVal = agg_min_array[2];
				}
				dbg("Min","NodeID %d AggregationMin value %u\n", TOS_NODE_ID, msgMin->minVal);
				call AggMinAMPacket.setDestination(&tmp, parentID);
				call AggMinPacket.setPayloadLength(&tmp, sizeof(AggregationMin));
				enqueueDone = call AggMinSendQueue.enqueue(tmp);
				if(enqueueDone == SUCCESS) {
					if(call AggMinSendQueue.size() == 1) {
						dbg("Min","SendAggMinTask posted!!\n");
						post sendAggMinTaskGroup();
					}
				dbg("Min","AggregationMin enqueued successfully in SendingQueue!!!\n");
				}
				}
			}
		}else if(aggType==AGGREGATION_TYPE_SUM_GROUP){
			uint8_t group_id = (TOS_NODE_ID % 3); 
			dbg("Sample","NodeID= %d : Group %u AggregationSum sample %u\n", TOS_NODE_ID, group_id + 1, sample);
			agg_sum_array[group_id] += sample;
			dbg("Sample","NodeID= %d : Group %u AggregationSum sumAfter= %u \n", TOS_NODE_ID, group_id + 1, agg_sum_array[group_id]);
			if(TOS_NODE_ID==0){
				uint8_t i=0;
				dbg("Results","***////////||||||\\\\\\***\n");
				for(i=0; i<3; i++){
					dbg("Results","AGG RESULT epoch=%u Group %u Sum=%u \n", epochCounter, i + 1, agg_sum_array[i]);
				}
				dbg("Results","***\\\\\\\\||||||//////***\n");
			}else{
				bool toSendForGroup1 = (agg_sum_array[0] != 0);
				bool toSendForGroup2 = (agg_sum_array[1] != 0);
				bool toSendForGroup3 = (agg_sum_array[2] != 0);
				if(toSendForGroup1 && toSendForGroup2 && toSendForGroup3){
					// send all three groups in one message
					Sum3Group* msgSum123;
					if(call QueueSendGroupSum3.full()){
						dbg("Sum","QueueSendGroupSum3 is FULL!!! \n");
						return;
					}
					msgSum123 = (Sum3Group*) (call AggSumPacketGroup123.getPayload(&tmp, sizeof(Sum3Group)));
					if(msgSum123==NULL){
						dbg("Sum","EpochTimer.fired(): No valid payload... \n");
						return;
					}
					atomic{
						msgSum123->sumGroup1 = agg_sum_array[0];
						msgSum123->sumGroup2 = agg_sum_array[1];
						msgSum123->sumGroup3 = agg_sum_array[2];
					}
					dbg("Sum","NodeID= %d : AggregationSum Group1=%u, Group2=%u, Group3=%u \n", TOS_NODE_ID, agg_sum_array[0], agg_sum_array[1], agg_sum_array[2]);
					call AggSumAMPacketGroup123.setDestination(&tmp, parentID);
					call AggSumPacketGroup123.setPayloadLength(&tmp, sizeof(Sum3Group));
					enqueueDone = call QueueSendGroupSum3.enqueue(tmp);

					if(enqueueDone==SUCCESS){
						if(call QueueSendGroupSum3.size()==1){
							dbg("Sum","sendSumGroup123() posted!!\n");
							post sendSumGroup123();
						}
						dbg("Sum","AggregationSum Group1,2,3 enqueued successfully in SendingQueue!!!\n");
					}
					
				}else if(toSendForGroup1 && toSendForGroup2){
					// send group 1 and 2
					Sum12Group* msgSum12;
					if(call QueueSendGroupSum2.full()){
						dbg("Sum","QueueSendGroupSum2 is FULL!!! \n");
						return;
					}
					msgSum12 = (Sum12Group*) (call AggSumPacketGroup12.getPayload(&tmp, sizeof(Sum12Group)));
					if(msgSum12==NULL){
						dbg("Sum","EpochTimer.fired(): No valid payload... \n");
						return;
					}
					atomic{
						msgSum12->sumGroup1 = agg_sum_array[0];
						msgSum12->sumGroup2 = agg_sum_array[1];
					}
					dbg("Sum","NodeID= %d : AggregationSum Group1=%u, Group2=%u \n", TOS_NODE_ID, agg_sum_array[0], agg_sum_array[1]);
					call AggSumAMPacketGroup12.setDestination(&tmp, parentID);
					call AggSumPacketGroup12.setPayloadLength(&tmp, sizeof(Sum12Group));
					enqueueDone = call QueueSendGroupSum2.enqueue(tmp);

					if(enqueueDone==SUCCESS){
						if(call QueueSendGroupSum2.size()==1){
							dbg("Sum","sendSumGroup12() posted!!\n");
							post sendSumGroup12();
						}
						dbg("Sum","AggregationSum Group1,2 enqueued successfully in SendingQueue!!!\n");
					}
				}else if(toSendForGroup1 && toSendForGroup3){
					// send group 1 and 3
					Sum13Group* msgSum13;
					if(call QueueSendGroupSum2.full()){
						dbg("Sum","QueueSendGroupSum2 is FULL!!! \n");
						return;
					}
					msgSum13 = (Sum13Group*) (call AggSumPacketGroup13.getPayload(&tmp, sizeof(Sum13Group)));
					if(msgSum13==NULL){
						dbg("Sum","EpochTimer.fired(): No valid payload... \n");
						return;
					}
					atomic{
						msgSum13->sumGroup1 = agg_sum_array[0];
						msgSum13->sumGroup3 = agg_sum_array[2];
					}
					dbg("Sum","NodeID= %d : AggregationSum Group1=%u, Group3=%u \n", TOS_NODE_ID, agg_sum_array[0], agg_sum_array[2]);
					call AggSumAMPacketGroup13.setDestination(&tmp, parentID);
					call AggSumPacketGroup13.setPayloadLength(&tmp, sizeof(Sum13Group));
					enqueueDone = call QueueSendGroupSum2.enqueue(tmp);

					if(enqueueDone==SUCCESS){
						if(call QueueSendGroupSum2.size()==1){
							dbg("Sum","sendSumGroup13() posted!!\n");
							post sendSumGroup13();
						}
						dbg("Sum","AggregationSum Group1,3 enqueued successfully in SendingQueue!!!\n");
					}
				}else if(toSendForGroup2 && toSendForGroup3){
					// send group 2 and 3
					Sum23Group* msgSum23;
					if(call QueueSendGroupSum2.full()){
						dbg("Sum","QueueSendGroupSum2 is FULL!!! \n");
						return;
					}
					msgSum23 = (Sum23Group*) (call AggSumPacketGroup23.getPayload(&tmp, sizeof(Sum23Group)));
					if(msgSum23==NULL){
						dbg("Sum","EpochTimer.fired(): No valid payload... \n");
						return;
					}
					atomic{
						msgSum23->sumGroup2 = agg_sum_array[1];
						msgSum23->sumGroup3 = agg_sum_array[2];
					}
					dbg("Sum","NodeID= %d : AggregationSum Group2=%u, Group3=%u \n", TOS_NODE_ID, agg_sum_array[1], agg_sum_array[2]);
					call AggSumAMPacketGroup23.setDestination(&tmp, parentID);
					call AggSumPacketGroup23.setPayloadLength(&tmp, sizeof(Sum23Group));
					enqueueDone = call QueueSendGroupSum2.enqueue(tmp);

					if(enqueueDone==SUCCESS){
						if(call QueueSendGroupSum2.size()==1){
							dbg("Sum","sendSumGroup23() posted!!\n");
							post sendSumGroup23();
						}
						dbg("Sum","AggregationSum Group2,3 enqueued successfully in SendingQueue!!!\n");
					}
				}else if(toSendForGroup1 || toSendForGroup2 || toSendForGroup3){
					// send only one group
					AggregationSum* msgSum;
					if(call AggSumSendQueue.full()){
						dbg("Sum","AggSumSendQueue is FULL!!! \n");
						return;
					}
					msgSum = (AggregationSum*) (call AggSumPacket.getPayload(&tmp, sizeof(AggregationSum)));
					if(msgSum==NULL){
						dbg("Sum","EpochTimer.fired(): No valid payload... \n");
						return;
					}
					atomic{
						if(toSendForGroup1){
							msgSum->sum = agg_sum_array[0];
						}else if(toSendForGroup2){
							msgSum->sum = agg_sum_array[1];
						}else if(toSendForGroup3){
							msgSum->sum = agg_sum_array[2];
						}
					}
					dbg("Sum","NodeID= %d : AggregationSum value= %u \n", TOS_NODE_ID, msgSum->sum);
					call AggSumAMPacket.setDestination(&tmp, parentID);
					call AggSumPacket.setPayloadLength(&tmp, sizeof(AggregationSum));
					enqueueDone = call AggSumSendQueue.enqueue(tmp);

					if(enqueueDone==SUCCESS){
						if(call AggSumSendQueue.size()==1){
							dbg("Sum","SendAggSumTask() posted!!\n");
							post sendAggSumTaskGroup();
						}
						dbg("Sum","AggregationSum enqueued successfully in SendingQueue!!!\n");
					}
				}
			}

		}
		agg_count=0;
		agg_sum=0;
		agg_min_array[0]=0xFFFF;
		agg_min_array[1]=0xFFFF;
		agg_min_array[2]=0xFFFF;
		agg_sum_array[0]=0;
		agg_sum_array[1]=0;
		agg_sum_array[2]=0;
		agg_min=0xFFFF;
	}
	
	task void sendMinGroup12Task() {
		uint8_t mlen; 
		uint16_t mdest; 
		error_t sendDone;
		dbg("Min","sendMinGroup12Task Starting....\n");
		if(call QueueSendGroupMin2.empty()) {
			dbg("Min","sendMinGroup12Task Q is empty!\n");
			return;
		}
		if(MinSendBusy) {
			dbg("Min","sendMinGroup12Task MinSendBusy TRUE!!!\n");
			post sendMinGroup12Task();
			return;
		}
		radioAggMinSendPkt = call QueueSendGroupMin2.dequeue();
		mlen = call AggMinPacketGroup12.payloadLength(&radioAggMinSendPkt);
		mdest = call AggMinAMPacketGroup12.destination(&radioAggMinSendPkt);
		if(mlen != sizeof(Min12Group)) {
			dbg("Min"," sendMinGroup12Task Unknown message!!!\n");
			return;
		}
		sendDone = call AggMinAMSendGroup12.send(mdest, &radioAggMinSendPkt, mlen);
		if(sendDone == SUCCESS) {
			dbg("Min","sendMinGroup12Task Send returned success!!!\n");
			setMinSendBusy(TRUE);
		}else {
			dbg("Min","send failed!!!\n");
		}
	}

	task void sendMinGroup13Task() {
		uint8_t mlen; 
		uint16_t mdest; 
		error_t sendDone;
		dbg("Min","sendMinGroup13Task Starting....\n");
		if(call QueueSendGroupMin2.empty()) {
			dbg("Min","sendMinGroup13Task Q is empty!\n");
			return;
		}
		if(MinSendBusy) {
			dbg("Min","sendMinGroup13Task MinSendBusy TRUE!!!\n");
			post sendMinGroup13Task();
			return;
		}
		radioAggMinSendPkt = call QueueSendGroupMin2.dequeue();
		mlen = call AggMinPacketGroup13.payloadLength(&radioAggMinSendPkt);
		mdest = call AggMinAMPacketGroup13.destination(&radioAggMinSendPkt);
		if(mlen != sizeof(Min13Group)) {
			dbg("Min"," sendMinGroup13Task Unknown message!!!\n");
			return;
		}
		sendDone = call AggMinAMSendGroup13.send(mdest, &radioAggMinSendPkt, mlen);
		if(sendDone == SUCCESS) {
			dbg("Min","sendMinGroup13Task Send returned success!!!\n");
			setMinSendBusy(TRUE);
		} else {
		dbg("Min","send failed!!!\n");
		}
	}

	task void sendMinGroup23Task() {
		uint8_t mlen; 
		uint16_t mdest; 
		error_t sendDone;
		dbg("Min","sendMinGroup23Task Starting....\n");
		if(call QueueSendGroupMin2.empty()) {
			dbg("Min","sendMinGroup23Task Q is empty!\n");
			return;
		}
		if(MinSendBusy) {
			dbg("Min","sendMinGroup23Task MinSendBusy TRUE!!!\n");
			post sendMinGroup23Task();
			return;
		}
		radioAggMinSendPkt = call QueueSendGroupMin2.dequeue();
		mlen = call AggMinPacketGroup23.payloadLength(&radioAggMinSendPkt);
		mdest = call AggMinAMPacketGroup23.destination(&radioAggMinSendPkt);
		if(mlen != sizeof(Min23Group)) {
			dbg("Min"," sendMinGroup23Task Unknown message!!!\n");
			return;
		}
		sendDone = call AggMinAMSendGroup23.send(mdest,&radioAggMinSendPkt, mlen);
		if(sendDone == SUCCESS) {
			dbg("Min","sendMinGroup23Task Send returned success!!!\n");
			setMinSendBusy(TRUE);
		} else {
			dbg("Min","send failed!!!\n");
		}
	}

	task void sendMinGroup123Task() {
		uint8_t mlen; uint16_t mdest; error_t sendDone;
		dbg("Min","sendMinGroup123Task Starting....\n");
		if(call QueueSendGroupMin3.empty()) {
			dbg("Min","sendMinGroup123Task Q is empty!\n");
			return;
		}
		if(MinSendBusy) {
			dbg("Min","sendMinGroup123Task MinSendBusy TRUE!!!\n");
			post sendMinGroup123Task();
			return;
		}
		radioAggMinSendPkt = call QueueSendGroupMin3.dequeue();
		mlen = call AggMinPacketGroup123.payloadLength(&radioAggMinSendPkt);
		mdest = call AggMinAMPacketGroup123.destination(&radioAggMinSendPkt);
		if(mlen != sizeof(Min3Group)) {
			dbg("Min"," sendMinGroup123Task Unknown message!!!\n");
			return;
		}
		sendDone = call AggMinAMSendGroup123.send(mdest, &radioAggMinSendPkt, mlen);
		if(sendDone == SUCCESS) {
			dbg("Min","sendMinGroup123Task Send returned success!!!\n");
			setMinSendBusy(TRUE);
		} else {
			dbg("Min","send failed!!!\n");
		}
	}

	task void receiveMinGroupTask(){
		uint8_t len;
		uint16_t msource;
		message_t radioMsg;
		AggregationMin* mpkt;
		uint8_t id;
		dbg("Min","receiveMinGroupTask():received msg...\n");
		radioMsg = call AggMinReceiveQueue.dequeue();
		msource = call AggMinAMPacketGroup.source(&radioMsg);
		len = call AggMinPacket.payloadLength(&radioMsg);
		dbg("Min","receiveMinGroupTask(): len=%u \n",len);
		if(len == sizeof(AggregationMin)){
			mpkt = (AggregationMin*) (call AggMinPacketGroup.getPayload(&radioMsg,len));
			if(mpkt==NULL){
				dbg("Min","receiveMinGroupTask(): No valid payload... \n");
				return;
			}
			id = (msource % 3);
			dbg("Min","receiveMinGroupTask(): Min receive= %u, for group = %u \n", mpkt->minVal , id+1);
			if(mpkt->minVal<agg_min_array[id]){
				agg_min_array[id] += mpkt->minVal;
			}else{
				dbg("Min","Packet value is bigger");
			}
			dbg("Min","Inside the receiveMinGroupTask(): New Min for this group = %u\n", agg_sum_array[id]);
		}
	}

	task void sendAggMinTaskGroup(){
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;
		dbg("Min","sendAggMinTaskGroup(): Starting....\n");
		if(call AggMinSendQueue.empty()){
			dbg("Min","sendAggMinTaskGroup(): Q is empty!\n");
			return;
		}
		if(MinSendBusy){
			dbg("Min","sendAggMinTaskGroup(): MinSendBusy= TRUE!!!\n");
			post sendAggMinTaskGroup();
			return;
		}
		radioAggMinSendPkt = call AggMinSendQueue.dequeue();
		mlen = call AggMinPacketGroup.payloadLength(&radioAggMinSendPkt);
		mdest = call AggMinAMPacketGroup.destination(&radioAggMinSendPkt);
		if(mlen!=sizeof(AggregationMin)){
			dbg("Min","\t\t sendAggMinTaskGroup(): Unknown message!!!\n");
			return;
		}
		
		sendDone = call AggMinAMSendGroup.send(mdest, &radioAggMinSendPkt, mlen);
		if(sendDone == SUCCESS ){
			dbg("Min","sendAggMinTaskGroup(): Send returned success!!!\n");
			setMinSendBusy(TRUE);
		}else{
			dbg("Min","send failed!!!\n");
		}
	}

	event void AggMinAMSendGroup.sendDone(message_t* msg, error_t err){
		dbg("Min","Inside the sendAggMinTaskGroup.sendDone() \n");
		dbg("Min","A AggregationMin package sent... %s \n",(err==SUCCESS)?"True":"False");
		setMinSendBusy(FALSE);
		if(!(call AggMinSendQueue.empty())){
			post sendAggMinTaskGroup();
		}
	}
	
	event message_t* AggMinReceiveGroup.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggMinAMPacketGroup.source(msg);
		dbg("Min","### AggMinReceiveGroup.receive() start ##### \n");
		dbg("Min","Something received!!!  from %u\n",  msource);
		
		atomic{
		memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call AggMinReceiveQueue.enqueue(tmp);
		if(enqueueDone == SUCCESS){
			dbg("Sum","posting receiveSumGroupTask()!!!! \n");
			post receiveMinGroupTask();
		}else{
			dbg("Sum","receiveSumGroupTask enqueue failed!!! \n");
		}
		return msg;
	}

	event message_t* AggMinReceiveGroup12.receive(message_t* msg, void* payload, uint8_t len) {
		message_t tmp;
		uint16_t msource = call AggMinAMPacketGroup12.source(msg);
		error_t enqueueDone;
		dbg("Min","AggMinReceiveGroup12.receive start\n");
		dbg("Min","Something received!!! from %u\n", msource);
		atomic{
			memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call QueueReceiveGroupMin2.enqueue(tmp);
		if(enqueueDone == SUCCESS) {
			dbg("Min","posting receiveMinGroup12Task!!!!\n");
			post receiveMinGroup12Task();
		} else {
			dbg("Min","receiveMinGroup12Task enqueue failed!!!\n");
		}
		return msg;
	}

	event message_t* AggMinReceiveGroup13.receive(message_t* msg, void* payload, uint8_t len) {
		message_t tmp;
		uint16_t msource = call AggMinAMPacketGroup13.source(msg);
		error_t enqueueDone;
		dbg("Min","AggMinReceiveGroup13.receive start\n");
		dbg("Min","Something received!!! from %u\n", msource);
		atomic{
			memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call QueueReceiveGroupMin2.enqueue(tmp);
		if(enqueueDone == SUCCESS) {
			dbg("Min","posting receiveMinGroup13Task!!!!\n");
			post receiveMinGroup13Task();
		} else {
			dbg("Min","receiveMinGroup13Task enqueue failed!!!\n");
		}
		return msg;
	}

	event message_t* AggMinReceiveGroup23.receive(message_t* msg, void* payload, uint8_t len) {
		message_t tmp;
		uint16_t msource = call AggMinAMPacketGroup23.source(msg);
		error_t enqueueDone;
		dbg("Min","AggMinReceiveGroup23.receive start\n");
		dbg("Min","Something received!!! from %u\n", msource);
		atomic{
			memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call QueueReceiveGroupMin2.enqueue(tmp);
		if(enqueueDone == SUCCESS) {
			dbg("Min","posting receiveMinGroup23Task!!!!\n");
			post receiveMinGroup23Task();
		} else {
			dbg("Min","receiveMinGroup23Task enqueue failed!!!\n");
		}
		return msg;
	}

	event message_t* AggMinReceiveGroup123.receive(message_t* msg, void* payload, uint8_t len) {
		message_t tmp;
		uint16_t msource = call AggMinAMPacketGroup123.source(msg);
		error_t enqueueDone;
		dbg("Min","AggMinReceiveGroup123.receive start\n");
		dbg("Min","Something received!!! from %u\n", msource);
		atomic{
			memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call QueueReceiveGroupMin3.enqueue(tmp);
		if(enqueueDone == SUCCESS) {
			dbg("Min","posting receiveMinGroup123Task!!!!\n");
			post receiveMinGroup123Task();
		} else {
			dbg("Min","receiveMinGroup123Task enqueue failed!!!\n");
		}
		return msg;
	}

	event void AggMinAMSendGroup12.sendDone(message_t* msg, error_t err) {
		dbg("Min","Inside the AggMinAMSendGroup12.sendDone\n");
		dbg("Min","A AggregationMin package sent... %s\n", err==SUCCESS?"True":"False");
		setMinSendBusy(FALSE);
		if(!call QueueSendGroupMin2.empty()) post sendMinGroup12Task();
	}

	event void AggMinAMSendGroup13.sendDone(message_t* msg, error_t err) {
		dbg("Min","Inside the AggMinAMSendGroup13.sendDone\n");
		dbg("Min","A AggregationMin package sent... %s\n", err==SUCCESS?"True":"False");
		setMinSendBusy(FALSE);
		if(!call QueueSendGroupMin2.empty()) post sendMinGroup13Task();
	}

	event void AggMinAMSendGroup23.sendDone(message_t* msg, error_t err) {
		dbg("Min","Inside the AggMinAMSendGroup23.sendDone\n");
		dbg("Min","A AggregationMin package sent... %s\n", err==SUCCESS?"True":"False");
		setMinSendBusy(FALSE);
		if(!call QueueSendGroupMin2.empty()) post sendMinGroup23Task();
	}

	event void AggMinAMSendGroup123.sendDone(message_t* msg, error_t err) {
		dbg("Min","Inside the AggMinAMSendGroup123.sendDone\n");
		dbg("Min","A AggregationMin package sent... %s\n", err==SUCCESS?"True":"False");
		setMinSendBusy(FALSE);
		if(!call QueueSendGroupMin3.empty()) post sendMinGroup123Task();
	}



	task void sendAggMinTask(){
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;

		dbg("Min","SendAggMinTask(): Starting....\n");
		if(call AggMinSendQueue.empty()){
			dbg("Min","SendAggMinTask(): Q is empty!\n");
			return;
		}
		if(MinSendBusy){
			dbg("Min","SendAggMinTask(): MinSendBusy= TRUE!!!\n");
			post sendAggMinTask();
			return;
		}
		radioAggMinSendPkt = call AggMinSendQueue.dequeue();
		mlen = call AggMinPacket.payloadLength(&radioAggMinSendPkt);
		mdest = call AggMinAMPacket.destination(&radioAggMinSendPkt);
		if(mlen!=sizeof(AggregationMin)){
			dbg("Min","\t\t SendAggMinTask(): Unknown message!!!\n");
			return;
		}
		
		sendDone = call AggMinAMSend.send(mdest, &radioAggMinSendPkt, mlen);
		if(sendDone == SUCCESS ){
			dbg("Min","SendAggMinTask(): Send returned success!!!\n");
			setMinSendBusy(TRUE);
		}else{
			dbg("Min","send failed!!!\n");
		}
	}

	task void sendAggSumTask(){
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;
		dbg("Sum","SendAggSumTask(): Starting....\n");
		if(call AggSumSendQueue.empty()){
			dbg("Sum","SendAggSumTask(): Q is empty!\n");
			return;
		}
		if(SumSendBusy){
			dbg("Sum","SendAggSumTask(): SumSendBusy= TRUE!!!\n");
			post sendAggSumTask();
			return;
		}
		radioAggSumSendPkt = call AggSumSendQueue.dequeue();
		mlen = call AggSumPacket.payloadLength(&radioAggSumSendPkt);
		mdest = call AggSumAMPacket.destination(&radioAggSumSendPkt);
		if(mlen!=sizeof(AggregationSum)){
			dbg("Sum","\t\t SendAggSumTask(): Unknown message!!!\n");
			return;
		}
		
		sendDone = call AggSumAMSend.send(mdest, &radioAggSumSendPkt, mlen);
		if(sendDone == SUCCESS ){
			dbg("Sum","SendAggSumTask(): Send returned success!!!\n");
			setSumSendBusy(TRUE);
		}else{
			dbg("Sum","send failed!!!\n");
		}
	}

	task void sendAggAvgTask(){
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;

		dbg("Avg","SendAggAvgTask(): Starting....\n");
		if(call AggAvgSendQueue.empty()){
			dbg("Avg","SendAggAvgTask(): Q is empty!\n");
			return;
		}
		if(AvgSendBusy){
			dbg("Avg","SendAggAvgTask(): AvgSendBusy= TRUE!!!\n");
			post sendAggAvgTask();
			return;
		}
		radioAggAvgSendPkt = call AggAvgSendQueue.dequeue();
		mlen = call AggAvgPacket.payloadLength(&radioAggAvgSendPkt);
		mdest = call AggAvgAMPacket.destination(&radioAggAvgSendPkt);
		if(mlen!=sizeof(AggregationAvg)){
			dbg("Avg","\t\t SendAggAvgTask(): Unknown message!!!\n");
			return;
		}
		
		sendDone = call AggAvgAMSend.send(mdest, &radioAggAvgSendPkt, mlen);
		if(sendDone == SUCCESS ){
			dbg("Avg","SendAggAvgTask(): Send returned success!!!\n");
			setAvgSendBusy(TRUE);
		}else{
			dbg("Avg","send failed!!!\n");
		}
	}

	task void sendAggSumTaskGroup(){
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;
		dbg("Sum","sendAggSumTaskGroup(): Starting....\n");
		if(call AggSumSendQueue.empty()){
			dbg("Sum","sendAggSumTaskGroup(): Q is empty!\n");
			return;
		}
		if(SumSendBusy){
			dbg("Sum","sendAggSumTaskGroup(): SumSendBusy= TRUE!!!\n");
			post sendAggSumTaskGroup();
			return;
		}
		radioAggSumSendPkt = call AggSumSendQueue.dequeue();
		mlen = call AggSumPacketGroup.payloadLength(&radioAggSumSendPkt);
		mdest = call AggSumAMPacketGroup.destination(&radioAggSumSendPkt);
		if(mlen!=sizeof(AggregationSum)){
			dbg("Sum","\t\t sendAggSumTaskGroup(): Unknown message!!!\n");
			return;
		}
		
		sendDone = call AggSumAMSentGroup.send(mdest, &radioAggSumSendPkt, mlen);
		if(sendDone == SUCCESS ){
			dbg("Sum","sendAggSumTaskGroup(): Send returned success!!!\n");
			setSumSendBusy(TRUE);
		}else{
			dbg("Sum","send failed!!!\n");
		}
	}

	event void AggSumAMSentGroup.sendDone(message_t* msg, error_t err){
		dbg("Sum","Inside the sendAggSumTaskGroup.sendDone() \n");
		dbg("Sum","A AggregationSum package sent... %s \n",(err==SUCCESS)?"True":"False");
		setSumSendBusy(FALSE);
		if(!(call AggSumSendQueue.empty())){
			post sendAggSumTaskGroup();
		}
	}

	event message_t* AggSumReceiveGroup.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggSumAMPacketGroup.source(msg);
		dbg("Sum","### AggSumReceiveGroup.receive() start ##### \n");
		dbg("Sum","Something received!!!  from %u\n",  msource);
		
		atomic{
		memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call AggSumReceiveQueue.enqueue(tmp);
		if(enqueueDone == SUCCESS){
			dbg("Sum","posting receiveSumGroupTask()!!!! \n");
			post receiveSumGroupTask();
		}else{
			dbg("Sum","receiveSumGroupTask enqueue failed!!! \n");
		}
		return msg;
	}

	task void receiveSumGroupTask(){
		uint8_t len;
		uint16_t msource;
		message_t radioMsg;
		AggregationSum* mpkt;
		uint8_t id;
		dbg("Sum","receiveSumGroupTask():received msg...\n");
		radioMsg = call AggSumReceiveQueue.dequeue();
		msource = call AggSumAMPacketGroup.source(&radioMsg);
		len = call AggSumPacketGroup.payloadLength(&radioMsg);
		dbg("Sum","receiveSumGroupTask(): len=%u \n",len);
		if(len == sizeof(AggregationSum)){
			mpkt = (AggregationSum*) (call AggSumPacketGroup.getPayload(&radioMsg,len));
			if(mpkt==NULL){
				dbg("Sum","receiveSumGroupTask(): No valid payload... \n");
				return;
			}
			id = (msource % 3);
			dbg("Sum","receiveSumGroupTask(): sum receive= %u, for group = %u \n", mpkt->sum , id+1);
			agg_sum_array[id] += mpkt->sum;
			dbg("Sum","Inside the receiveSumGroupTask(): New sum for this group = %u\n", agg_sum_array[id]);
		}
	}

	task void sendSumGroup12(){
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;
		dbg("Sum","sendSumGroup12(): Starting....\n");
		if(call QueueSendGroupSum2.empty()){
			dbg("Sum","sendSumGroup12(): Q is empty!\n");
			return;
		}
		if(SumSendBusy){
			dbg("Sum","sendSumGroup12(): SumSendBusy= TRUE!!!\n");
			post sendSumGroup12();
			return;
		}
		radioAggSumSendPkt = call QueueSendGroupSum2.dequeue();
		mlen = call AggSumPacketGroup12.payloadLength(&radioAggSumSendPkt);
		mdest = call AggSumAMPacketGroup12.destination(&radioAggSumSendPkt);
		if(mlen!=sizeof(Sum12Group)){
			dbg("Sum","\t\t sendSumGroup12(): Unknown message!!!\n");
			return;
		}
		
		sendDone = call AggSumAMSendGroup12.send(mdest, &radioAggSumSendPkt, mlen);
		if(sendDone == SUCCESS ){
			dbg("Sum","sendSumGroup12(): Send returned success!!!\n");
			setSumSendBusy(TRUE);
		}else{
			dbg("Sum","send failed!!!\n");
		}
	}

	event void AggSumAMSendGroup12.sendDone(message_t* msg, error_t err){
		dbg("Sum","Inside the AggSumAMSendGroup12.sendDone() \n");
		dbg("Sum","A AggregationSum package sent... %s \n",(err==SUCCESS)?"True":"False");
		setSumSendBusy(FALSE);
		if(!(call QueueSendGroupSum2.empty())){
			post sendSumGroup12();
		}
	}

	task void sendSumGroup13(){
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;
		dbg("Sum","sendSumGroup13(): Starting....\n");
		if(call QueueSendGroupSum2.empty()){
			dbg("Sum","sendSumGroup13(): Q is empty!\n");
			return;
		}
		if(SumSendBusy){
			dbg("Sum","sendSumGroup13(): SumSendBusy= TRUE!!!\n");
			post sendSumGroup13();
			return;
		}
		radioAggSumSendPkt = call QueueSendGroupSum2.dequeue();
		mlen = call AggSumPacketGroup13.payloadLength(&radioAggSumSendPkt);
		mdest = call AggSumAMPacketGroup13.destination(&radioAggSumSendPkt);
		if(mlen!=sizeof(Sum13Group)){
			dbg("Sum","\t\t sendSumGroup13(): Unknown message!!!\n");
			return;
		}

		sendDone = call AggSumAMSendGroup13.send(mdest, &radioAggSumSendPkt, mlen);
		if(sendDone == SUCCESS ){
			dbg("Sum","sendSumGroup13(): Send returned success!!!\n");
			setSumSendBusy(TRUE);
		}else{
			dbg("Sum","send failed!!!\n");
		}
	}

	event void AggSumAMSendGroup13.sendDone(message_t* msg, error_t err){
		dbg("Sum","Inside the AggSumAMSendGroup13.sendDone() \n");
		dbg("Sum","A AggregationSum package sent... %s \n",(err==SUCCESS)?"True":"False");
		setSumSendBusy(FALSE);
		if(!(call QueueSendGroupSum2.empty())){
			post sendSumGroup13();
		}
	}

	task void sendSumGroup23(){
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;
		dbg("Sum","sendSumGroup23(): Starting....\n");
		if(call QueueSendGroupSum2.empty()){
			dbg("Sum","sendSumGroup23(): Q is empty!\n");
			return;
		}
		if(SumSendBusy){
			dbg("Sum","sendSumGroup23(): SumSendBusy= TRUE!!!\n");
			post sendSumGroup23();
			return;
		}
		radioAggSumSendPkt = call QueueSendGroupSum2.dequeue();
		mlen = call AggSumPacketGroup23.payloadLength(&radioAggSumSendPkt);
		mdest = call AggSumAMPacketGroup23.destination(&radioAggSumSendPkt);
		if(mlen!=sizeof(Sum23Group)){
			dbg("Sum","\t\t sendSumGroup23(): Unknown message!!!\n");
			return;
		}

		sendDone = call AggSumAMSendGroup23.send(mdest, &radioAggSumSendPkt, mlen);
		if(sendDone == SUCCESS ){
			dbg("Sum","sendSumGroup23(): Send returned success!!!\n");
			setSumSendBusy(TRUE);
		}else{
			dbg("Sum","send failed!!!\n");
		}
			return;
	}
	

	event void AggSumAMSendGroup23.sendDone(message_t* msg, error_t err){
		dbg("Sum","Inside the AggSumAMSendGroup23.sendDone() \n");
		dbg("Sum","A AggregationSum package sent... %s \n",(err==SUCCESS)?"True":"False");
		setSumSendBusy(FALSE);
		if(!(call QueueSendGroupSum2.empty())){
			post sendSumGroup23();
		}
	}

	task void sendSumGroup123(){
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;
		dbg("Sum","sendSumGroup123(): Starting....\n");
		if(call QueueSendGroupSum3.empty()){
			dbg("Sum","sendSumGroup123(): Q is empty!\n");
			return;
		}
		if(SumSendBusy){
			dbg("Sum","sendSumGroup123(): SumSendBusy= TRUE!!!\n");
			post sendSumGroup123();
			return;
		}
		radioAggSumSendPkt = call QueueSendGroupSum3.dequeue();
		mlen = call AggSumPacketGroup123.payloadLength(&radioAggSumSendPkt);
		mdest = call AggSumAMPacketGroup123.destination(&radioAggSumSendPkt);
		if(mlen!=sizeof(Sum3Group)){
			dbg("Sum","\t\t sendSumGroup123(): Unknown message!!!\n");
			return;
		}

		sendDone = call AggSumAMSendGroup123.send(mdest, &radioAggSumSendPkt, mlen);
		if(sendDone == SUCCESS ){
			dbg("Sum","sendSumGroup123(): Send returned success!!!\n");
			setSumSendBusy(TRUE);
		}else{
			dbg("Sum","send failed!!!\n");
		}
	}

	event void AggSumAMSendGroup123.sendDone(message_t* msg, error_t err){
		dbg("Sum","Inside the AggSumAMSendGroup123.sendDone() \n");
		dbg("Sum","A AggregationSum package sent... %s \n",(err==SUCCESS)?"True":"False");
		setSumSendBusy(FALSE);
		if(!(call QueueSendGroupSum3.empty())){
			post sendSumGroup123();
		}
	}

	event void AggMinAMSend.sendDone(message_t* msg, error_t err){
		dbg("Min","Inside the AggMinAMSend.sendDone() \n");
		dbg("Min","A AggregationMin package sent... %s \n",(err==SUCCESS)?"True":"False");
		setMinSendBusy(FALSE);
		if(!(call AggMinSendQueue.empty())){
			post sendAggMinTask();
		}
	}
	event void AggSumAMSend.sendDone(message_t* msg, error_t err){
		dbg("Sum","Inside the AggSumAMSend.sendDone() \n");
		dbg("Sum","A AggregationSum package sent... %s \n",(err==SUCCESS)?"True":"False");
		setSumSendBusy(FALSE);
		if(!(call AggSumSendQueue.empty())){
			post sendAggSumTask();
		}
	}

	event void AggAvgAMSend.sendDone(message_t* msg, error_t err){
		dbg("Avg","Inside the AggAvgAMSend.sendDone() \n");
		dbg("Avg","A AggregationAvg package sent... %s \n",(err==SUCCESS)?"True":"False");
		setAvgSendBusy(FALSE);
		if(!(call AggAvgSendQueue.empty())){
			post sendAggAvgTask();
		}
	}

	event message_t* AggMinReceive.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggMinAMPacket.source(msg);
		dbg("Min","### AggMinReceive.receive() start ##### \n");
		dbg("Min","Something received!!!  from %u\n",  msource);
		
		atomic{
		memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call AggMinReceiveQueue.enqueue(tmp);
		if(enqueueDone == SUCCESS){
			dbg("Min","posting receiveAggMinTask()!!!! \n");
			post receiveAggMinTask();
		}else{
			dbg("Min","AggMinMsg enqueue failed!!! \n");
		}
		return msg;
	}

	event message_t* AggSumReceive.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggSumAMPacket.source(msg);
		dbg("Sum","### AggSumReceive.receive() start ##### \n");
		dbg("Sum","Something received!!!  from %u\n",  msource);
		
		atomic{
		memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call AggSumReceiveQueue.enqueue(tmp);
		if(enqueueDone == SUCCESS){
			dbg("Sum","posting receiveAggSumTask()!!!! \n");
			post receiveAggSumTask();
		}else{
			dbg("Sum","AggSumMsg enqueue failed!!! \n");
		}
		return msg;
	}

	event message_t* AggAvgReceive.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggAvgAMPacket.source(msg);
		dbg("Avg","### AggAvgReceive.receive() start ##### \n");
		dbg("Avg","Something received!!!  from %u\n",  msource);
		
		atomic{
		memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call AggAvgReceiveQueue.enqueue(tmp);
		if(enqueueDone == SUCCESS){
			dbg("Avg","posting receiveAggAvgTask()!!!! \n");
			post receiveAggAvgTask();
		}else{
			dbg("Avg","AggAvgMsg enqueue failed!!! \n");
		}
		return msg;
	}

	event message_t* AggSumReceiveGroup12.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggSumAMPacketGroup12.source(msg);
		dbg("Sum","### AggSumReceiveGroup12.receive() start ##### \n");
		dbg("Sum","Something received!!!  from %u\n",  msource);
		
		atomic{
		memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call QueueReceiveGroupSum2.enqueue(tmp);
		if(enqueueDone == SUCCESS){
			dbg("Sum","posting receiveSumGroup12Task()!!!! \n");
			post receiveSumGroup12Task();
		}else{
			dbg("Sum","receiveSumGroup12Task enqueue failed!!! \n");
		}
		return msg;
	}

	event message_t* AggSumReceiveGroup13.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggSumAMPacketGroup13.source(msg);
		dbg("Sum","### AggSumReceiveGroup13.receive() start ##### \n");
		dbg("Sum","Something received!!!  from %u\n",  msource);
		
		atomic{
		memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call QueueReceiveGroupSum2.enqueue(tmp);
		if(enqueueDone == SUCCESS){
			dbg("Sum","posting receiveSumGroup13Task()!!!! \n");
			post receiveSumGroup13Task();
		}else{
			dbg("Sum","receiveSumGroup13Task enqueue failed!!! \n");
		}
		return msg;
	}

	event message_t* AggSumReceiveGroup23.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggSumAMPacketGroup23.source(msg);
		dbg("Sum","### AggSumReceiveGroup23.receive() start ##### \n");
		dbg("Sum","Something received!!!  from %u\n",  msource);
		
		atomic{
		memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call QueueReceiveGroupSum2.enqueue(tmp);
		if(enqueueDone == SUCCESS){
			dbg("Sum","posting receiveSumGroup23Task()!!!! \n");
			post receiveSumGroup23Task();
		}else{
			dbg("Sum","receiveSumGroup23Task enqueue failed!!! \n");
		}
		return msg;
	}

	event message_t* AggSumReceiveGroup123.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggSumAMPacketGroup123.source(msg);
		dbg("Sum","### AggSumReceiveGroup123.receive() start ##### \n");
		dbg("Sum","Something received!!!  from %u\n",  msource);
		
		atomic{
		memcpy(&tmp, msg, sizeof(message_t));
		}
		enqueueDone = call QueueReceiveGroupSum3.enqueue(tmp);
		if(enqueueDone == SUCCESS){
			dbg("Sum","posting receiveSumGroup123Task()!!!! \n");
			post receiveSumGroup123Task();
		}else{
			dbg("Sum","receiveSumGroup123Task enqueue failed!!! \n");
		}
		return msg;
	}

	task void receiveAggMinTask(){
		uint8_t len;
		//uint16_t msource;
		message_t radioAggMinRecPkt;
		AggregationMin* mpkt;

		dbg("Min","ReceiveAggMinTask():received msg...\n");
		radioAggMinRecPkt = call AggMinReceiveQueue.dequeue();
		len = call AggMinPacket.payloadLength(&radioAggMinRecPkt);
		dbg("Min","ReceiveAggMinTask(): len=%u \n",len);
		if(len == sizeof(AggregationMin)){
			mpkt = (AggregationMin*) (call AggMinPacket.getPayload(&radioAggMinRecPkt,len));
			if(mpkt==NULL){
				dbg("Min","receiveAggMinTask(): No valid payload... \n");
				return;
			}
			dbg("Min","receiveAggMinTask(): minVal= %u \n", mpkt->minVal);
			if(mpkt->minVal < agg_min){
				agg_min = mpkt->minVal;
				dbg("Min","Inside the ReceiveAggMinTask(): New agg_min = %u \n", agg_min);
			}
		}//dbg("Sample","New sample = %u \n", sample);
	}

	task void receiveAggSumTask(){
		uint8_t len;
		//uint16_t msource;
		message_t radioAggSumRecPkt;
		AggregationSum* mpkt;
		dbg("Sum","ReceiveAggSumTask():received msg...\n");
		radioAggSumRecPkt = call AggSumReceiveQueue.dequeue();
		len = call AggSumPacket.payloadLength(&radioAggSumRecPkt);
		dbg("Sum","ReceiveAggSumTask(): len=%u \n",len);
		if(len == sizeof(AggregationSum)){
			mpkt = (AggregationSum*) (call AggSumPacket.getPayload(&radioAggSumRecPkt,len));
			if(mpkt==NULL){
				dbg("Sum","receiveAggSumTask(): No valid payload... \n");
				return;
			}
			dbg("Sum","receiveAggSumTask(): sum= %u \n", mpkt->sum);
			agg_sum += mpkt->sum;
			dbg("Sum","Inside the ReceiveAggSumTask(): New agg_sum = %u \n", agg_sum);
			
		}//dbg("Sample","New sample = %u \n", sample);
	}

	task void receiveSumGroup12Task(){
		uint8_t len;
		//uint16_t msource;
		message_t radioMsg;
		Sum12Group* mpkt;
		dbg("Sum","receiveSumGroup12Task():received msg...\n");
		radioMsg = call QueueReceiveGroupSum2.dequeue();
		len = call AggSumPacketGroup12.payloadLength(&radioMsg);
		dbg("Sum","receiveSumGroup12Task(): len=%u \n",len);
		if(len == sizeof(Sum12Group)){
			mpkt = (Sum12Group*) (call AggSumPacketGroup12.getPayload(&radioMsg,len));
			if(mpkt==NULL){
				dbg("Sum","receiveSumGroup12Task(): No valid payload... \n");
				return;
			}
			dbg("Sum","receiveSumGroup12Task(): sum group1= %u, sum group2= %u \n", mpkt->sumGroup1, mpkt->sumGroup2);
			agg_sum_array[1] += mpkt->sumGroup1;
			agg_sum_array[2] += mpkt->sumGroup2;
			dbg("Sum","Inside the receiveSumGroup12Task(): New sum 1 = %u sum 2 = %u \n", agg_sum_array[1], agg_sum_array[2]);
		}
	}

	task void receiveSumGroup13Task(){
		uint8_t len;
		//uint16_t msource;
		message_t radioMsg;
		Sum13Group* mpkt;
		dbg("Sum","receiveSumGroup13Task():received msg...\n");
		radioMsg = call QueueReceiveGroupSum2.dequeue();
		len = call AggSumPacketGroup13.payloadLength(&radioMsg);
		dbg("Sum","receiveSumGroup13Task(): len=%u \n",len);
		if(len == sizeof(Sum13Group)){
			mpkt = (Sum13Group*) (call AggSumPacketGroup13.getPayload(&radioMsg,len));
			if(mpkt==NULL){
				dbg("Sum","receiveSumGroup13Task(): No valid payload... \n");
				return;
			}
			dbg("Sum","receiveSumGroup13Task(): sum group1= %u, sum group3= %u \n", mpkt->sumGroup1, mpkt->sumGroup3);
			agg_sum_array[1] += mpkt->sumGroup1;
			agg_sum_array[3] += mpkt->sumGroup3;
			dbg("Sum","Inside the receiveSumGroup13Task(): New sum 1 = %u sum 3 = %u \n", agg_sum_array[1], agg_sum_array[3]);
		}
	}

	task void receiveSumGroup23Task(){
		uint8_t len;
		//uint16_t msource;
		message_t radioMsg;
		Sum23Group* mpkt;
		dbg("Sum","receiveSumGroup23Task():received msg...\n");
		radioMsg = call QueueReceiveGroupSum2.dequeue();
		len = call AggSumPacketGroup23.payloadLength(&radioMsg);
		dbg("Sum","receiveSumGroup23Task(): len=%u \n",len);
		if(len == sizeof(Sum23Group)){
			mpkt = (Sum23Group*) (call AggSumPacketGroup23.getPayload(&radioMsg,len));
			if(mpkt==NULL){
				dbg("Sum","receiveSumGroup23Task(): No valid payload... \n");
				return;
			}
			dbg("Sum","receiveSumGroup23Task(): sum group2= %u, sum group3= %u \n", mpkt->sumGroup2, mpkt->sumGroup3);
			agg_sum_array[3] += mpkt->sumGroup3;
			agg_sum_array[2] += mpkt->sumGroup2;
			dbg("Sum","Inside the receiveSumGroup23Task(): New sum 2 = %u sum 3 = %u \n", agg_sum_array[2], agg_sum_array[3]);
		}
	}

	task void receiveSumGroup123Task(){
		uint8_t len;
		//uint16_t msource;
		message_t radioMsg;
		Sum3Group* mpkt;
		dbg("Sum","receiveSumGroup123Task():received msg...\n");
		radioMsg = call QueueReceiveGroupSum3.dequeue();
		len = call AggSumPacketGroup123.payloadLength(&radioMsg);
		dbg("Sum","receiveSumGroup123Task(): len=%u \n",len);
		if(len == sizeof(Sum3Group)){
			mpkt = (Sum3Group*) (call AggSumPacketGroup123.getPayload(&radioMsg,len));
			if(mpkt==NULL){
				dbg("Sum","receiveSumGroup123Task(): No valid payload... \n");
				return;
			}
			dbg("Sum","receiveSumGroup123Task(): sum group1= %u, sum group2= %u, sum group3= %u \n", mpkt->sumGroup1, mpkt->sumGroup2, mpkt->sumGroup3);
			agg_sum_array[1] += mpkt->sumGroup1;
			agg_sum_array[2] += mpkt->sumGroup2;
			agg_sum_array[3] += mpkt->sumGroup3;
			dbg("Sum","Inside the receiveSumGroup123Task(): New sum 1 = %u sum 2 = %u sum 3 = %u \n", agg_sum_array[1], agg_sum_array[2], agg_sum_array[3]);
		}
	}

	task void receiveAggAvgTask(){
		uint8_t len;
		//uint16_t msource;
		message_t radioAggAvgRecPkt;
		AggregationAvg* mpkt;

		dbg("Avg","ReceiveAggAvgTask():received msg...\n");
		radioAggAvgRecPkt = call AggAvgReceiveQueue.dequeue();
		len = call AggAvgPacket.payloadLength(&radioAggAvgRecPkt);
		dbg("Avg","ReceiveAggAvgTask(): len=%u \n",len);
		if(len == sizeof(AggregationAvg)){
			mpkt = (AggregationAvg*) (call AggAvgPacket.getPayload(&radioAggAvgRecPkt,len));
			if(mpkt==NULL){
				dbg("Avg","receiveAggAvgTask(): No valid payload... \n");
				return;
			}
			dbg("Avg","receiveAggAvgTask(): sum= %u, count = %u \n", mpkt->sum, mpkt->count);
			//msource = call AggMinAMPacket.source(&radioAggMinRecPkt);
			agg_count += mpkt->count;
			agg_sum += mpkt->sum;
			dbg("Avg","Inside the ReceiveAggAvgTask(): New agg_sum = %u, New agg_count = %u \n", agg_sum, agg_count);
		}//dbg("Sample","New sample = %u \n", sample);
	}
}
