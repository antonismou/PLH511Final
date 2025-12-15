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

	components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueueC;
	//components new PacketQueueC(SENDER_QUEUE_SIZE) as NotifySendQueueC;
	//components new PacketQueueC(RECEIVER_QUEUE_SIZE) as NotifyReceiveQueueC;
	//ADDED
	components new PacketQueueC(SENDER_QUEUE_SIZE) as AggMinSendQueueC;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as AggMinReceiveQueueC;
    components new AMSenderC(AGGREGATION_TYPE_MIN) as AggMinSenderC;
    components new AMReceiverC(AGGREGATION_TYPE_MIN) as AggMinReceiverC;

	components new PacketQueueC(SENDER_QUEUE_SIZE) as AggAvgSendQueueC;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as AggAvgReceiveQueueC;
    components new AMSenderC(AGGREGATION_TYPE_AVG) as AggAvgSenderC;
    components new AMReceiverC(AGGREGATION_TYPE_AVG) as AggAvgReceiverC;

	components new PacketQueueC(SENDER_QUEUE_SIZE) as AggSumSendQueueC;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as AggSumReceiveQueueC;
    components new AMSenderC(AGGREGATION_TYPE_SUM) as AggSumSenderC;
    components new AMReceiverC(AGGREGATION_TYPE_SUM) as AggSumReceiverC;
//------ phase 2
	//min
	components new PacketQueueC(SENDER_QUEUE_SIZE) as QueueSendGroupMin2C;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as QueueReceiveGroupMin2C;

    components new AMSenderC(ID_MSG_MIN_GROUP_1_2) as AggMinSenderGroup12C;
    components new AMReceiverC(ID_MSG_MIN_GROUP_1_2) as AggMinReceiverGroup12C;
	components new AMSenderC(ID_MSG_MIN_GROUP_1_3) as AggMinSenderGroup13C;
    components new AMReceiverC(ID_MSG_MIN_GROUP_1_3) as AggMinReceiverGroup13C;
	components new AMSenderC(ID_MSG_MIN_GROUP_2_3) as AggMinSenderGroup23C;
	components new AMReceiverC(ID_MSG_MIN_GROUP_2_3) as AggMinReceiverGroup23C;

	components new PacketQueueC(SENDER_QUEUE_SIZE) as QueueSendGroupMin3C;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as QueueReceiveGroupMin3C;
	components new AMSenderC(ID_MSG_MIN_GROUP_1_2_3) as AggMinSenderGroup123C;
	components new AMReceiverC(ID_MSG_MIN_GROUP_1_2_3) as AggMinReceiverGroup123C;
	
	components new AMSenderC(ID_MSG_SUM_GROUP) as AggSumSenderGroupC;
	components new AMReceiverC(ID_MSG_SUM_GROUP) as AggSumReceiverGroupC;

	components new PacketQueueC(SENDER_QUEUE_SIZE) as QueueSendGroupSum2C;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as QueueReceiveGroupSum2C;
    components new AMSenderC(ID_MSG_SUM_GROUP_1_2) as AggSumSenderGroup12C;
    components new AMReceiverC(ID_MSG_SUM_GROUP_1_2) as AggSumReceiverGroup12C;
	components new AMSenderC(ID_MSG_SUM_GROUP_1_3) as AggSumSenderGroup13C;
    components new AMReceiverC(ID_MSG_SUM_GROUP_1_3) as AggSumReceiverGroup13C;
	components new AMSenderC(ID_MSG_SUM_GROUP_2_3) as AggSumSenderGroup23C;
	components new AMReceiverC(ID_MSG_SUM_GROUP_2_3) as AggSumReceiverGroup23C;

	components new PacketQueueC(SENDER_QUEUE_SIZE) as QueueSendGroupSum3C;
    components new PacketQueueC(RECEIVER_QUEUE_SIZE) as QueueReceiveGroupSum3C;
	components new AMSenderC(ID_MSG_SUM_GROUP_1_2_3) as AggSumSenderGroup123C;
	components new AMReceiverC(ID_MSG_SUM_GROUP_1_2_3) as AggSumReceiverGroup123C;


    components new TimerMilliC() as EpochTimerC;
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

	SRTreeC.AggAvgPacket->AggAvgSenderC.Packet;
    SRTreeC.AggAvgAMPacket->AggAvgSenderC.AMPacket;
    SRTreeC.AggAvgAMSend->AggAvgSenderC.AMSend;
    SRTreeC.AggAvgReceive->AggAvgReceiverC.Receive;
    SRTreeC.AggAvgSendQueue->AggAvgSendQueueC;
    SRTreeC.AggAvgReceiveQueue->AggAvgReceiveQueueC;

	SRTreeC.AggSumPacket->AggSumSenderC.Packet;
    SRTreeC.AggSumAMPacket->AggSumSenderC.AMPacket;
    SRTreeC.AggSumAMSend->AggSumSenderC.AMSend;
    SRTreeC.AggSumReceive->AggSumReceiverC.Receive;
    SRTreeC.AggSumSendQueue->AggSumSendQueueC;
    SRTreeC.AggSumReceiveQueue->AggSumReceiveQueueC;


	//------ phase 2
	//min
	SRTreeC.QueueSendGroupMin2->QueueSendGroupMin2C;
	SRTreeC.QueueReceiveGroupMin2->QueueReceiveGroupMin2C;

	SRTreeC.AggMinPacketGroup12->AggMinSenderGroup12C.Packet;
	SRTreeC.AggMinAMPacketGroup12->AggMinSenderGroup12C.AMPacket;
	SRTreeC.AggMinAMSendGroup12->AggMinSenderGroup12C.AMSend;
	SRTreeC.AggMinReceiveGroup12->AggMinReceiverGroup12C.Receive;
	
	SRTreeC.AggMinPacketGroup13->AggMinSenderGroup13C.Packet;
	SRTreeC.AggMinAMPacketGroup13->AggMinSenderGroup13C.AMPacket;
	SRTreeC.AggMinAMSendGroup13->AggMinSenderGroup13C.AMSend;
	SRTreeC.AggMinReceiveGroup13->AggMinReceiverGroup13C.Receive;

	SRTreeC.AggMinPacketGroup23->AggMinSenderGroup23C.Packet;
	SRTreeC.AggMinAMPacketGroup23->AggMinSenderGroup23C.AMPacket;
	SRTreeC.AggMinAMSendGroup23->AggMinSenderGroup23C.AMSend;
	SRTreeC.AggMinReceiveGroup23->AggMinReceiverGroup23C.Receive;

	SRTreeC.QueueSendGroupMin3->QueueSendGroupMin3C;
	SRTreeC.QueueReceiveGroupMin3->QueueReceiveGroupMin3C;

	SRTreeC.AggMinPacketGroup123->AggMinSenderGroup123C.Packet;
	SRTreeC.AggMinAMPacketGroup123->AggMinSenderGroup123C.AMPacket;
	SRTreeC.AggMinAMSendGroup123->AggMinSenderGroup123C.AMSend;
	SRTreeC.AggMinReceiveGroup123->AggMinReceiverGroup123C.Receive;
	
	//sum
	SRTreeC.AggSumPacketGroup->AggSumSenderGroupC.Packet;
	SRTreeC.AggSumAMPacketGroup->AggSumSenderGroupC.AMPacket;
	SRTreeC.AggSumAMSentGroup->AggSumSenderGroupC.AMSend;
	SRTreeC.AggSumReceiveGroup->AggSumReceiverGroupC.Receive;

	SRTreeC.QueueSendGroupSum2->QueueSendGroupSum2C;
	SRTreeC.QueueReceiveGroupSum2->QueueReceiveGroupSum2C;

	SRTreeC.AggSumPacketGroup12->AggSumSenderGroup12C.Packet;
	SRTreeC.AggSumAMPacketGroup12->AggSumSenderGroup12C.AMPacket;
	SRTreeC.AggSumAMSendGroup12->AggSumSenderGroup12C.AMSend;
	SRTreeC.AggSumReceiveGroup12->AggSumReceiverGroup12C.Receive;

	SRTreeC.AggSumPacketGroup13->AggSumSenderGroup13C.Packet;
	SRTreeC.AggSumAMPacketGroup13->AggSumSenderGroup13C.AMPacket;
	SRTreeC.AggSumAMSendGroup13->AggSumSenderGroup13C.AMSend;
	SRTreeC.AggSumReceiveGroup13->AggSumReceiverGroup13C.Receive;

	SRTreeC.AggSumPacketGroup23->AggSumSenderGroup23C.Packet;
	SRTreeC.AggSumAMPacketGroup23->AggSumSenderGroup23C.AMPacket;
	SRTreeC.AggSumAMSendGroup23->AggSumSenderGroup23C.AMSend;
	SRTreeC.AggSumReceiveGroup23->AggSumReceiverGroup23C.Receive;

	SRTreeC.QueueSendGroupSum3->QueueSendGroupSum3C;
	SRTreeC.QueueReceiveGroupSum3->QueueReceiveGroupSum3C;

	SRTreeC.AggSumPacketGroup123->AggSumSenderGroup123C.Packet;
	SRTreeC.AggSumAMPacketGroup123->AggSumSenderGroup123C.AMPacket;
	SRTreeC.AggSumAMSendGroup123->AggSumSenderGroup123C.AMSend;
	SRTreeC.AggSumReceiveGroup123->AggSumReceiverGroup123C.Receive;
	//phase 2 end

    SRTreeC.EpochTimer->EpochTimerC;

	SRTreeC.Seed->RandomMlcgC.SeedInit;

	//END ADDED
}
