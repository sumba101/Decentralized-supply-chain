// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
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
        uint ownerId;
    }

    struct ComponentType {
        uint id;
        string name;
        uint[] subcomponentTypeIds;
        // uint[] subcomponentQuantities;
    }

    Party[maxParties] public parties;
    mapping(address => uint) partyNum;

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
        require(parties[party1].tier > parties[party2].tier ,"Buyer has to be in a tier lower than or equal to seller");
        _;
    }

    /**
    * Modifier ensures id exists
    *
    * @param id Id to check
    * @param limit The upperbound, given by respective counter
    * @param mesg The error message to display
    */
    modifier idCheck(uint id,uint limit, string memory mesg) {
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
            message = "Order "; // ????????
        } else if (orders[orderId].status == OrderStatus.CONFIRMED) {
            message = "Order  ";
        }else if (orders[orderId].status == OrderStatus.SHIPPED) {
            message = "Order ";
        } 
        else if (orders[orderId].status == OrderStatus.FINISHED) {
            message = "Order ";
        } else if (orders[orderId].status == OrderStatus.CANCELLED) {
            message = " ";
        } else {
            message = "Error. Please try initiating the transaction again.";
        }
        
        require(orders[orderId].status == status, message);
        _;
    }


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


    function addParty(string memory name, bool isDeliveryParty, uint tier, string memory location) public {
        parties[partiesCounter] = Party(partiesCounter, msg.sender, name, isDeliveryParty, tier, location);
        partyNum[msg.sender] = partiesCounter;
        partiesCounter++;
    }

    function addComponentType(string memory name, uint[] memory subcomponents) public {
        for (uint i = 0; i < subcomponents.length; i++) {
            require(subcomponents[i] < componentTypesCounter, "Subcomponent type does not exist");
        }

        componentTypes[componentTypesCounter] = ComponentType(componentTypesCounter, name, subcomponents);
        componentTypesCounter++;
    }

    function addComponent(uint componentTypeId, uint[] memory subcomponents) public 
    idCheck(componentTypeId,componentTypesCounter,"Component type does not exist")
    {
        require(parties[partyNum[msg.sender]].owner == msg.sender, "Sender does not belong to any party");
        
        ComponentType memory componentType = componentTypes[componentTypeId];
        require(componentType.subcomponentTypeIds.length == subcomponents.length, "Number of subcomponents given is wrong");
        for (uint i = 0; i < subcomponents.length; i++) {
            // string memory errorText = string(abi.encodePacked());
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
    tierParity(partyNum[msg.sender],sellerId)    
    {
        require(parties[partyNum[msg.sender]].owner == msg.sender, "Sender does not belong to any party");

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

    function fillOrder(uint orderId, uint componentTypeId, uint[] memory componentIds) public {
        require(parties[partyNum[msg.sender]].owner == msg.sender, "Sender does not belong to any party");
        require(partyNum[msg.sender] == orders[orderId].sellerId, "Sender does not belong to the seller party");

        for (uint j = 0; j < componentIds.length; j++) {
            require(componentIds[j] < componentsCounter, "At least one component does not exist");
        }

        for (uint i = 0; i < orders[orderId].orderComponents.length; i++) {
            if (orders[orderId].orderComponents[i].componentTypeId == componentTypeId) {
                require(orders[orderId].orderComponents[i].quantity == componentIds.length, 
                    "Wrong quantity of component IDs provided");
                orders[orderId].orderComponents[i].componentIds = componentIds; 
                break;
            }
        }
    }

    function createShipment(uint buyerId, uint sellerId,uint shipperId) public 
    idCheck(shipmentsCounter+1,maxShipments,"Maximum number of shipments reached")
    {
        shipmentsCounter ++;
        uint [maxOrdersInShipment] memory tempOrdersInShipment;
        shipments[shipmentsCounter]= Shipment(shipmentsCounter,0,tempOrdersInShipment,buyerId,sellerId,shipperId);
     }

    function addOrderToShipment(uint orderId, uint shipmentId) public 
    idCheck(orderId, ordersCounter,"Order Id does not exist")
    idCheck(shipmentId, shipmentsCounter,"Shipment Id does not exist")
    idCheck(shipments[shipmentId].numberOfOrders,maxOrdersInShipment,"Maximum orders in shipment reached")
    {
        uint temp = shipments[shipmentId].numberOfOrders;
        temp+=1;

        shipments[shipmentId].orders[temp] = orderId;
        shipments[shipmentId].numberOfOrders = temp;
    }


    function updateOrderStatus(uint orderId) public {
        OrderStatus currentStatus = orders[orderId].status;
        
        if(currentStatus == OrderStatus.PLACED){
            orders[orderId].status = OrderStatus.CONFIRMED;
        }
        else if(currentStatus == OrderStatus.CONFIRMED){
            orders[orderId].status = OrderStatus.SHIPPED;
        }
        else if(currentStatus == OrderStatus.SHIPPED){
            orders[orderId].status = OrderStatus.FINISHED;
        }
        else if(currentStatus == OrderStatus.CANCELLED){
            orders[orderId].status = OrderStatus.PLACED;
        }
    }

    
    function cancelOrder(uint orderId) public
    idCheck(orderId, ordersCounter,"Order Id does not exist")
    checkStatus(orderId,OrderStatus.PLACED)
    {
        orders[orderId].status = OrderStatus.CANCELLED;
    }

    function updateShipmentStatus(uint shipmentId) public 
    idCheck(shipmentId, shipmentsCounter,"Shipment Id does not exist")
    {
        for (uint i = 0; i < shipments[shipmentId].numberOfOrders; i++) {
            uint tempOrderId = shipments[shipmentId].orders[i];
            orders[tempOrderId].status = OrderStatus.SHIPPED;
        }
    }


 /*  C: sefhdziukhesd => {
            sefhdziukhesd
            0
            []
            esdf
        }

        CT: 0 => {
            0
            "screw"
            []
        }

        C: dlsoxnmjgfdsxf => {
            dlsoxnmjgfdsxf
            1
            []
            saas
        }

        CT: 1 => {
            1
            "wood"
            []
        }

        CT: 2 => {
            2
            "table"
            [ 0, 1 ]
        }

        C: sadsadsad => {
            sadsadsad
            3
            []
        }

        CT: 3 : "chair"

        C: hkifhsdf => {
            hkifhsdf
            2
            [ sefhdziukhesd, sadsadsad ]
        }
    */

}

