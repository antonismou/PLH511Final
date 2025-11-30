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

	uses interface PacketQueue as AggQuerySendQueue;
	uses interface PacketQueue as AggQueryReceiveQueue;

	uses interface Packet as AggMinPacket;
	uses interface AMPacket as AggMinAMPacket;
	uses interface AMSend as AggMinAMSend;
	uses interface Receive as AggMinReceive;
	uses interface PacketQueue as AggMinSendQueue;
	uses interface PacketQueue as AggMinReceiveQueue;
	/* --- commented out for testing perposes
	uses interface Packet as AggSumPacket;
	uses interface AMSend as AggSumAMSend;
	uses interface Receive as AggSumReceive;
	uses interface PacketQueue as AggSumSendQueue;
	uses interface PacketQueue as AggSumReceiveQueue;

	uses interface Packet as AggAvgPacket;
	uses interface AMSend as AggAvgAMSend;
	uses interface Receive as AggAvgReceive;
	uses interface PacketQueue as AggAvgSendQueue;
	uses interface PacketQueue as AggAvgReceiveQueue;
	*/
	uses interface Timer<TMilli> as EpochTimer;
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
	uint8_t aggType;
	uint16_t sample;
	uint16_t epochCounter;
	uint16_t agg_min;
	uint32_t agg_sum;
	uint16_t agg_count;
	bool AvgSendBusy=FALSE;	
	bool MinSendBusy=FALSE;	
	bool SumSendBusy=FALSE;
	//END ADDED

	task void sendRoutingTask();
	task void receiveRoutingTask();
	task void sendAggMinTask();
	task void receiveAggMinTask();
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
		
		setRoutingSendBusy(FALSE);
		setAvgSendBusy(FALSE);
		setMinSendBusy(FALSE);
		setSumSendBusy(FALSE);
		//setNotifySendBusy(FALSE); no tag
		#ifdef SERIAL_EN
		setSerialBusy(FALSE);
		#endif
		roundCounter =0;
		
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
			//aggType= (call Random.rand16() %3) +1; // 1=MIN,2=SUM,3=AVG
			aggType=1; // for testing only MIN
			//call RoutingMsgTimer.startOneShot(TIMER_PERIOD_MILLI);
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
			mrpkt->senderID=TOS_NODE_ID;
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
		dbg("Routing", "Something received!!!  from %u  %u \n",((RoutingMsg*) payload)->senderID ,  msource);
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
			dbg("Epoch","Start epoch timer for node %d \n", TOS_NODE_ID);
			call EpochTimer.startPeriodicAt(EPOCH_PERIOD_MILLI - (curdepth*WINDOW_MILLI),EPOCH_PERIOD_MILLI);
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
			
			dbg("Routing" , "receiveRoutingTask():senderID= %d , depth= %d \n", mpkt->senderID , mpkt->depth);
			#ifdef PRINTFDBG_MODE
			printf("NodeID= %d , RoutingMsg received! \n",TOS_NODE_ID);
			printf("receiveRoutingTask():senderID= %d , depth= %d \n", mpkt->senderID , mpkt->depth);
			printfflush();
			#endif
			if ( (parentID<0)||(parentID>=65535))
			{
				// tote den exei akoma patera
				parentID= call RoutingAMPacket.source(&radioRoutingRecPkt);//mpkt->senderID;q
				curdepth= mpkt->depth + 1;
				aggType = mpkt->aggType;
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


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////	
	
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
		uint16_t temp;
		error_t enqueueDone;
		AggregationMin* msgMin;
		AggregationSUM* msgSum;
		AggregationAVG* msgAvg;

		dbg("Epoch","EpochTimer fired! \n");

		epochCounter+=1;
		if(epochCounter==1){
			sample = (call Random.rand16() % 60) + 1; // random sample between 1 and 60
		}else{
			sample = (sample * ((call Random.rand16() % 40) + 80)) / 100; // * 0.8 to 1.2
			if(sample > 60){
				sample = 60;
			}
		}
		dbg("Sample","New sample = %u \n", sample);
		if(aggType==AGGREGATION_TYPE_MIN){
			if(sample < agg_min){
				temp = sample;
				agg_min = sample;
			}else{
				temp = agg_min;
			}
			if(TOS_NODE_ID==0){
				dbg("Results","AGG RESULT epoch=%u MIN=%u \n", epochCounter, agg_min);
			}else{
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
				msgMin->senderID = TOS_NODE_ID;
				msgMin->minVal = agg_min;
				msgMin->epoch = epochCounter;
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
			// similar for SUM
		}else if(aggType==AGGREGATION_TYPE_AVG){
			// similar for AVG
		}
	}

	task void sendAggMinTask(){
		message_t radioAggMinSendPkt;
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
		if(sendDone==SUCCESS){
			dbg("Min","SendAggMinTask(): Send returned success!!!\n");
			setMinSendBusy(TRUE);
		}else{
			dbg("Min","send failed!!!\n");
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

	event message_t* AggMinReceive.receive(message_t* msg, void* payload, uint8_t len){
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;

		msource = call AggMinAMPacket.source(msg);
		dbg("Min","### AggMinReceive.receive() start ##### \n");
		dbg("Min","Something received!!!  from %u  %u \n",((AggregationMin*) payload)->senderID ,  msource);
		
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

	task void receiveAggMinTask(){
		uint8_t len;
		uint16_t msource;
		message_t radioAggMinRecPkt;
		AggregationMin* mpkt;

		dbg("Min","ReceiveAggMinTask():received msg...\n");
		radioAggMinRecPkt = call AggMinReceiveQueue.dequeue();
		len = call AggMinPacket.payloadLength(&radioAggMinRecPkt);
		dbg("Min","ReceiveAggMinTask(): len=%u \n",len);
		if(len == sizeof(AggregationMin)){
			dbg("Min","receiveAggMinTask():senderID= %d , minVal= %u , epoch= %u \n", mpkt->senderID , mpkt->minVal, mpkt->epoch);
			msource = call AggMinAMPacket.source(&radioAggMinRecPkt);
			mpkt = (AggregationMin*) (call AggMinPacket.getPayload(&radioAggMinRecPkt,len));
			if(mpkt==NULL){
				dbg("Min","receiveAggMinTask(): No valid payload... \n");
				return;
			}
			if(mpkt->epoch != epochCounter){
				dbg("Min","receiveAggMinTask(): epoch mismatch (received=%u , current=%u) \n", mpkt->epoch, epochCounter);
				return;
			}else if(mpkt->minVal < agg_min){
				agg_min = mpkt->minVal;
				dbg("Min","NodeID= %d : New agg_min = %u \n", TOS_NODE_ID, agg_min);
			}
		}
	}
}
