# Decentralized-supply-chain
A decentralized supply chain trace- ability application that uses input at every step of the way to ensure accountability and quality.


### Structures used
* Party
	Each party is represented by a party object. The contract has a global list of parties identified by their unique addresses.

	It tracks the parties name, role (Whether delivery party or not), tier, and location

* Component Type
	It is the basic blueprint of the component, tracking its pre-requisite sub components

	It tracks component type name and subcomponents  

* Component
	A component is any part or a product of multiple parts in the manufacturing process. A set of components can only be combined to form a new component if the correct amounts of them are available.

	It tracks the subcomponents, component type and manufacturer address

* Order
	It is a purchase of a particular component types in a specified quantity by a given party

	It tracks shipment id, buyer, seller, order status and components with their corresponding quantities

* Shipment
	The delivery requirement from one delivery partner to a non delivery partner is tracked in shipment.

	It tracks the list of orders, buyer, seller, shipping location and the logistics service provider

### Workflow
* Required parties in the process (both delivery providers and non delivery providers) are created with addParty function
* Basic component types are added along with corresponding components with addComponentType and addComponent
* Orders are placed using placeOrder
* The respective orders are filled using fillOrder
* Orders are confirmed by delivery providers with confirmOrder
	* Up until an order has been confirmed, either order buyer or seller have the ability to cancel it with cancelOrder
* Shipment is created by delivery service providing party and orders are added to shipment with addOrderToShipment
* Upon shipment completion the orders are finished with completeShipment

