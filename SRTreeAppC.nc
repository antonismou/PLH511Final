#include "SimpleRoutingTree.h"

configuration SRTreeAppC @safe() { }
implementation{
	components SRTreeC;
	components RandomC , RandomMlcgC;

#if defined(DELUGE) //defined(DELUGE_BASESTATION) || defined(DELUGE_LIGHT_BASESTATION)
	components DelugeC;
#endif

#ifdef PRINTFDBG_MODE
		components PrintfC;
#endif
	components MainC, ActiveMessageC, SerialActiveMessageC, LedsC;
	components new TimerMilliC() as Led0TimerC;
	components new TimerMilliC() as Led1TimerC;
	components new TimerMilliC() as Led2TimerC;
	components new TimerMilliC() as RoutingMsgTimerC;
	components new TimerMilliC() as LostTaskTimerC;
	
	components new AMSenderC(AM_ROUTINGMSG) as RoutingSenderC;
	components new AMReceiverC(AM_ROUTINGMSG) as RoutingReceiverC;
	//components new AMSenderC(AM_NOTIFYPARENTMSG) as NotifySenderC;
	//components new AMReceiverC(AM_NOTIFYPARENTMSG) as NotifyReceiverC;
#ifdef SERIAL_EN
	components new SerialAMSenderC(AM_NOTIFYPARENTMSG);
	components new SerialAMReceiverC(AM_NOTIFYPARENTMSG);
#endif
	components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueueC;
	//components new PacketQueueC(SENDER_QUEUE_SIZE) as NotifySendQueueC;
	//components new PacketQueueC(RECEIVER_QUEUE_SIZE) as NotifyReceiveQueueC;
	//ADDED
	components new PacketQueueC(SENDER_QUEUE_SIZE) as AggMinSendQueueC;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as AggMinReceiveQueueC;
    components new AMSenderC(AGGREGATION_TYPE_MIN) as AggMinSenderC;
    components new AMReceiverC(AGGREGATION_TYPE_MIN) as AggMinReceiverC;

    components new TimerMilliC() as EpochTimerC;
	components new TimerMilliC() as SeasonTimerC;
	//END ADDED
	SRTreeC.Boot->MainC.Boot;
	
	SRTreeC.RadioControl -> ActiveMessageC;
	SRTreeC.Leds-> LedsC;
	
	SRTreeC.Led0Timer-> Led0TimerC;
	SRTreeC.Led1Timer-> Led1TimerC;
	SRTreeC.Led2Timer-> Led2TimerC;
	SRTreeC.RoutingMsgTimer->RoutingMsgTimerC;
	//SRTreeC.LostTaskTimer->LostTaskTimerC;
	
	SRTreeC.RoutingPacket->RoutingSenderC.Packet;
	SRTreeC.RoutingAMPacket->RoutingSenderC.AMPacket;
	SRTreeC.RoutingAMSend->RoutingSenderC.AMSend;
	SRTreeC.RoutingReceive->RoutingReceiverC.Receive;
/* no tag
	SRTreeC.NotifyPacket->NotifySenderC.Packet;
	SRTreeC.NotifyAMPacket->NotifySenderC.AMPacket;
	SRTreeC.NotifyAMSend->NotifySenderC.AMSend;
	SRTreeC.NotifyReceive->NotifyReceiverC.Receive;
*/
#ifdef SERIAL_EN	
	SRTreeC.SerialReceive->SerialAMReceiverC.Receive;
	SRTreeC.SerialAMSend->SerialAMSenderC.AMSend;
	SRTreeC.SerialAMPacket->SerialAMSenderC.AMPacket;
	SRTreeC.SerialPacket->SerialAMSenderC.Packet;
	SRTreeC.SerialControl->SerialActiveMessageC;
#endif
	SRTreeC.RoutingSendQueue->RoutingSendQueueC;
	SRTreeC.RoutingReceiveQueue->RoutingReceiveQueueC;
	//SRTreeC.NotifySendQueue->NotifySendQueueC;
	//SRTreeC.NotifyReceiveQueue->NotifyReceiveQueueC;
	
	//ADDED
	SRTreeC.Random->RandomC;
	SRTreeC.AggMinPacket->AggMinSenderC.Packet;
    SRTreeC.AggMinAMPacket->AggMinSenderC.AMPacket;
    SRTreeC.AggMinAMSend->AggMinSenderC.AMSend;
    SRTreeC.AggMinReceive->AggMinReceiverC.Receive;
    SRTreeC.AggMinSendQueue->AggMinSendQueueC;
    SRTreeC.AggMinReceiveQueue->AggMinReceiveQueueC;
    SRTreeC.EpochTimer->EpochTimerC;

	SRTreeC.Seed->RandomMlcgC.SeedInit;

	//END ADDED
}
