// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract SupplyChain {
    uint constant maxOrders = 100;
    uint constant maxParties = 10;
    uint constant maxShipments = 100;
    uint constant maxComponents = 1000;
    uint constant maxComponentTypes = 500;
    uint constant maxOrdersInShipment = 10;
    uint constant maxSubcomponents = 100;
    uint constant maxComponentsInOrder = 100;

    enum OrderStatus {
        PLACED,
        CONFIRMED,
        SHIPPED,
        FINISHED,
        CANCELLED
    }

    struct Party {
        uint id;
        address owner;
        string name;
        bool isDeliveryParty;
        uint tier;
        string location;
    }

    struct OrderComponent {
        uint componentTypeId;
        uint quantity;
        uint[] componentIds;
    }

    struct Order {
        uint id;
        OrderComponent[maxComponentsInOrder] orderComponents;
        int shipmentId;
        uint buyerId;
        uint sellerId;
        OrderStatus status; 
        /*
            PLACED,
            CONFIRMED,
            SHIPPED,
            FINISHED,
            CANCELLED
        */
    }

    struct Shipment {
        uint id;
        uint numberOfOrders;
        uint[maxOrdersInShipment] orders;
        uint buyerId;
        uint sellerId;
        uint shipperId;
    }

    struct Component {
        uint id;
        uint componentTypeId;
        // uint[] subcomponentTypeIds;
        uint[] subcomponentIds;
        uint manufacturerId;
        uint possessorId;
    }

    struct ComponentType {
        uint id;
        string name;
        uint[] subcomponentTypeIds;
        // uint[] subcomponentQuantities;
    }

    Party[maxParties] public parties;
    mapping(address => uint) public partyNum;

    ComponentType[maxComponentTypes] public componentTypes;
    Component[maxComponentTypes] public components;
    Order[maxOrders] public orders;
    Shipment[maxShipments] shipments;

    uint partiesCounter = 0;
    uint componentTypesCounter = 0;
    uint componentsCounter = 0;
    uint ordersCounter = 0;
    uint shipmentsCounter = 0;

    /**
    * Modifier ensure party levels
    *
    * @param party1 address of first party
    * @param party2 address of second party
    */
    modifier tierParity(uint party1,uint party2) {
        require(parties[party1].tier <= parties[party2].tier ,"Buyer has to be in a tier lower than or equal to seller");
        _;
    }

    /**
    * Modifier ensures id exists
    *
    * @param id Id to check
    * @param limit The upperbound, given by respective counter
    * @param mesg The error message to display
    */
    modifier idCheck(uint id, uint limit, string memory mesg) {
        require(id <= limit && id>=0 ,mesg);
        _;
    }

    /**
    * Modifier to check the status of a given order
    *
    * @param orderId ID of order
    * @param status required status, used to compare with order status
    */
    modifier checkStatus(uint orderId, OrderStatus status) {       
        string memory message = "GG";
        if (orders[orderId].status == OrderStatus.PLACED) {
            message = "Order has to be confirmed"; // ????????
        } else if (orders[orderId].status == OrderStatus.CONFIRMED) {
            message = "Order has been confirmed, has to be shipped";
        } else if (orders[orderId].status == OrderStatus.SHIPPED) {
            message = "Order has been shipped";
        } else if (orders[orderId].status == OrderStatus.FINISHED) {
            message = "Order has been delivered and finished";
        } else if (orders[orderId].status == OrderStatus.CANCELLED) {
            message = "Order has been cancelled";
        } else {
            message = "Error. Please try initiating the shipment again.";
        }
        
        require(orders[orderId].status == status, message);
        _;
    }

// ======================================

    function viewComponentTypes() public view returns(ComponentType[] memory) {
        ComponentType[] memory componentTypesViewer = new ComponentType[](componentTypesCounter);
        for (uint i = 0; i < componentTypesCounter; i++) {
            componentTypesViewer[i] = componentTypes[i];
        }
        return componentTypesViewer;
    }

    function viewComponents() public view returns(Component[] memory) {
        Component[] memory componentsViewer = new Component[](componentsCounter);
        for (uint i = 0; i < componentsCounter; i++) {
            componentsViewer[i] = components[i];
        }
        return componentsViewer;
    }

    function viewOrders() public view returns(Order[] memory) {
        Order[] memory ordersViewer = new Order[](ordersCounter);
        for (uint i = 0; i < ordersCounter; i++) {
            ordersViewer[i] = orders[i];
        }
        return ordersViewer;
    }

    function viewOrder(uint id) public 
    idCheck(id,ordersCounter,"Order id doesnt exist")
    view returns(Order memory) {
        Order memory ordersViewer = orders[id];
        return ordersViewer;
    }

    function viewShipments() public view returns(Shipment[] memory) {
        Shipment[] memory shipmentView = new Shipment[](shipmentsCounter);
        for (uint i = 0; i < shipmentsCounter; i++) {
            shipmentView[i] = shipments[i];
        }
        return shipmentView;
    }

    function viewShipment(uint id) public 
    idCheck(id,shipmentsCounter,"Shipment id does not exist")
    view returns(Shipment memory) {
        Shipment memory shipmentView = shipments[id];
        return shipmentView;
    }

// =============================================

    function addParty(string memory name, bool isDeliveryParty, uint tier, string memory location) public 
    idCheck(partiesCounter,maxParties,"Maximum number of parties reached")
    {
        parties[partiesCounter] = Party(partiesCounter, msg.sender, name, isDeliveryParty, tier, location);
        partyNum[msg.sender] = partiesCounter;
        partiesCounter++;
    }

    function addComponentType(string memory name, uint[] memory subcomponents) public 
    idCheck(componentTypesCounter,maxComponentTypes,"Maximum number of component types reached")
    {
        for (uint i = 0; i < subcomponents.length; i++) {
            require(subcomponents[i] < componentTypesCounter, "Subcomponent type does not exist");
        }

        componentTypes[componentTypesCounter] = ComponentType(componentTypesCounter, name, subcomponents);
        componentTypesCounter++;
    }

    event Debug(uint);

    function addComponent(uint componentTypeId, uint[] memory subcomponents) public 
    idCheck(componentsCounter,maxComponents,"Maximum number of components reached")
    idCheck(componentTypeId,componentTypesCounter,"Component type does not exist")
    {
        require(parties[partyNum[msg.sender]].owner == msg.sender, "Sender does not belong to any party");
        
        
        ComponentType storage componentType = componentTypes[componentTypeId];

        emit Debug(componentType.subcomponentTypeIds.length);
        emit Debug(subcomponents.length);

        require(componentType.subcomponentTypeIds.length == subcomponents.length, "Number of subcomponents given is wrong");

        for (uint i = 0; i < subcomponents.length; i++) {
            require(subcomponents[i] < componentsCounter, "At least one subcomponent does not exist");
            require(components[subcomponents[i]].componentTypeId == componentType.subcomponentTypeIds[i], 
                "At least one subcomponent is of the wrong type");
        }

        components[componentsCounter] = Component(componentsCounter, componentTypeId, 
            subcomponents, partyNum[msg.sender], partyNum[msg.sender]);
        componentsCounter++;
    }

    function placeOrder(uint sellerId, uint[] memory componentTypeIds, uint[] memory quantities) public 
    idCheck(sellerId,partiesCounter,"Seller does not exist")
    idCheck(ordersCounter,maxOrders,"Maximum number of orders reached")
    tierParity(partyNum[msg.sender],sellerId)    
    {
        require(parties[partyNum[msg.sender]].owner == msg.sender, "Sender does not belong to any party");
        require(parties[sellerId].owner != msg.sender, "Buyer cannot be the seller");
        require(parties[sellerId].isDeliveryParty != true, "Seller cannot be a delivery party");

        for (uint i = 0; i < quantities.length; i++) {
            require(componentTypeIds[i] < componentTypesCounter, "Component type does not exist");
            require(quantities[i] > 0, "Invalid quantity");

            orders[ordersCounter].orderComponents[i].quantity = quantities[i];
            orders[ordersCounter].orderComponents[i].componentTypeId = componentTypeIds[i];
            orders[ordersCounter].orderComponents[i].componentIds = new uint[](0);

        }

        orders[ordersCounter].id = ordersCounter;
        orders[ordersCounter].shipmentId = -1;
        orders[ordersCounter].buyerId = partyNum[msg.sender];
        orders[ordersCounter].sellerId = sellerId;
        orders[ordersCounter].status = OrderStatus.PLACED;
    
        ordersCounter++;
    }

    function fillOrder(uint orderId, uint componentTypeId, uint[] memory componentIds) public 
    {
        require(parties[partyNum[msg.sender]].owner == msg.sender, "Sender does not belong to any party");
        require(partyNum[msg.sender] == orders[orderId].sellerId, "Sender does not belong to the seller party");

        for (uint j = 0; j < componentIds.length; j++) {
            require(componentIds[j] < componentsCounter, "At least one component does not exist");
            require(components[componentIds[j]].possessorId == partyNum[msg.sender], "At least one component is not owned by sender");
        }

        bool found = false;
        for (uint i = 0; i < orders[orderId].orderComponents.length; i++) {
            if (orders[orderId].orderComponents[i].componentTypeId == componentTypeId) {
                require(orders[orderId].orderComponents[i].quantity == componentIds.length, 
                    "Wrong quantity of component IDs provided");
                orders[orderId].orderComponents[i].componentIds = componentIds; 
                found = true;
                break;
            }
        }
        if (found == false) {
            revert("Wrong component type ID");
        }
    }

    function createShipment(uint buyerId, uint sellerId) public 
    idCheck(shipmentsCounter,maxShipments,"Maximum number of shipments reached")
    {
        require(parties[partyNum[msg.sender]].isDeliveryParty == true, "Party is not delivery party and cannot create shipment");
        
        uint [maxOrdersInShipment] memory tempOrdersInShipment;
        shipments[shipmentsCounter]= Shipment(shipmentsCounter, 0, tempOrdersInShipment, buyerId, sellerId, partyNum[msg.sender]);
        shipmentsCounter++;
    }

    function addOrderToShipment(uint orderId, uint shipmentId) public 
    idCheck(orderId, ordersCounter,"Order Id does not exist")
    idCheck(shipmentId, shipmentsCounter,"Shipment Id does not exist")
    idCheck(shipments[shipmentId].numberOfOrders, maxOrdersInShipment,"Maximum orders in shipment reached")
    {
        require(parties[partyNum[msg.sender]].isDeliveryParty == true, "Party is not delivery party and cannot add to shipment");
        require(shipments[shipmentId].shipperId == partyNum[msg.sender], "Sender is not the shipper");

        orders[orderId].shipmentId = int(partyNum[msg.sender]);
        uint temp = shipments[shipmentId].numberOfOrders;
        shipments[shipmentId].orders[temp] = orderId;
        temp+=1;
        shipments[shipmentId].numberOfOrders = temp;
    }

    function confirmOrder(uint orderId) public 
    idCheck(orderId,ordersCounter,"Order Id does not exist")
    checkStatus(orderId,OrderStatus.PLACED)
    {
        require(partyNum[msg.sender] == orders[orderId].sellerId, "Sender is not the seller. Only seller can confirm order");
        orders[orderId].status = OrderStatus.CONFIRMED;
        
    }
    
    function cancelOrder(uint orderId) public
    idCheck(orderId, ordersCounter,"Order Id does not exist")
    checkStatus(orderId,OrderStatus.PLACED)
    {
        require(partyNum[msg.sender] == orders[orderId].buyerId || partyNum[msg.sender] == orders[orderId].sellerId, 
            "Sender is not buyer or seller");
        orders[orderId].status = OrderStatus.CANCELLED;
    }

    function updateShipmentStatus(uint shipmentId) public 
    idCheck(shipmentId, shipmentsCounter,"Shipment Id does not exist")
    {
        require(shipments[shipmentId].shipperId == partyNum[msg.sender], "Sender is not shipper");
        for (uint i = 0; i < shipments[shipmentId].numberOfOrders; i++) {
            uint tempOrderId = shipments[shipmentId].orders[i];
            require(orders[tempOrderId].status == OrderStatus.CONFIRMED,"All orders in shipment have not been confirmed");
            orders[tempOrderId].status = OrderStatus.SHIPPED;

            for (uint j = 0; j < orders[tempOrderId].orderComponents.length; j++) {
                for (uint k = 0; k < orders[tempOrderId].orderComponents[j].componentIds.length; k++) {
                    components[orders[tempOrderId].orderComponents[j].componentIds[k]].possessorId = partyNum[msg.sender];
                }
            }
        }
    }

    function completeShipment(uint shipmentId) public 
    idCheck(shipmentId, shipmentsCounter,"Shipment Id does not exist")
    {
        require(shipments[shipmentId].shipperId == partyNum[msg.sender], "Sender is not shipper");
        for (uint i = 0; i < shipments[shipmentId].numberOfOrders; i++) {
            uint tempOrderId = shipments[shipmentId].orders[i];
            require(orders[tempOrderId].status == OrderStatus.SHIPPED,"All orders in shipment have not been confirmed");
            orders[tempOrderId].status = OrderStatus.FINISHED;

            
            for (uint j = 0; j < orders[tempOrderId].orderComponents.length; j++) {
                for (uint k = 0; k < orders[tempOrderId].orderComponents[j].componentIds.length; k++) {
                    components[orders[tempOrderId].orderComponents[j].componentIds[k]].possessorId = orders[tempOrderId].buyerId;
                }
            }
        }
    }

}


