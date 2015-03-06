export Interface
export clearMessage!, setMessage!, message, name

type Interface
    # An Interface belongs to a node and is used to send/receive messages.
    # An Interface has exactly one partner interface, with wich it forms an edge.
    # An Interface can be seen as a half-edge, that connects to a partner Interface to form a complete edge.
    # A message from node a to node b is stored at the Interface of node a that connects to an Interface of node b.
    node::Node
    edge::Union(AbstractEdge, Nothing)
    partner::Union(Interface, Nothing)  # Partner indicates the interface to which it is connected.
    child::Union(Interface, Nothing)    # An interface that belongs to a composite has a child, which is the corresponding (effectively the same) interface one lever deeper in the node hierarchy.
    message::Union(Message, Nothing)
    internal_schedule::Array{Any, 1}    # Optional schedule that should be executed to calculate outbound message on this interface.
                                        # The internal_schedule field is used in composite nodes, and holds the schedule for internal message passing.

    # Sanity check for matching message types
    function Interface(node::Node, edge::Union(AbstractEdge, Nothing)=nothing, partner::Union(Interface, Nothing)=nothing, child::Union(Interface, Nothing)=nothing, message::Union(Message, Nothing)=nothing)
        if typeof(partner) == Nothing || typeof(message) == Nothing # Check if message or partner exist
            return new(node, edge, partner, child, message)
        elseif typeof(message) != typeof(partner.message) # Compare message types
            error("Message type of partner does not match with interface message type")
        else
            return new(node, edge, partner, child, message)
        end
    end
end
Interface(node::Node, message::Message) = Interface(node, nothing, nothing, nothing, message)
Interface(node::Node) = Interface(node, nothing, nothing, nothing, nothing)
function show(io::IO, interface::Interface)
    iface_name = name(interface)
    (iface_name == "") || (iface_name = "($(iface_name))")
    println(io, "Interface $(findfirst(interface.node.interfaces, interface)) $(iface_name) of $(typeof(interface.node)) $(interface.node.name)")
end
function setMessage!(interface::Interface, message::Message)
    interface.message = deepcopy(message)
end
clearMessage!(interface::Interface) = (interface.message=nothing)
message(interface::Interface) = interface.message
function name(interface::Interface)
    # Return interface name
    for field in names(interface.node)
        if isdefined(interface.node, field) && is(getfield(interface.node, field), interface)
            return string(field)
        end
    end
    return ""
end

function ensureMessage!{T<:ProbabilityDistribution}(interface::Interface, payload_type::Type{T})
    # Ensure that interface carries a Message{payload_type}, used for in place updates
    if interface.message == nothing || typeof(interface.message.payload) != payload_type
        if payload_type <: DeltaDistribution
            interface.message = Message(payload_type())
        else
            interface.message = Message(vague(payload_type))
        end
    end

    return interface.message
end
