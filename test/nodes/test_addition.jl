facts("AdditionNode") do
    context("AdditionNode() should initialize an AdditionNode with 3 interfaces") do
        node = AdditionNode()
        @fact typeof(node) => AdditionNode
        @fact length(node.interfaces) => 3
        @fact node.in1 => node.interfaces[1]
        @fact node.in2 => node.interfaces[2]
        @fact node.out => node.interfaces[3]
    end

    context("AdditionNode should add two GeneralMessages") do
        node = AdditionNode()
        inbound_msg_1 = GeneralMessage(2.0)
        inbound_msg_2 = GeneralMessage(3.0)
        # Forward message
        msg = ForneyLab.updateNodeMessage!(3, node, [inbound_msg_1, inbound_msg_2, GeneralMessage()])
        @fact node.interfaces[3].message => msg
        @fact node.interfaces[3].message.value => 5.0
        # Backward message
        msg = ForneyLab.updateNodeMessage!(1, node, [GeneralMessage(), inbound_msg_1, inbound_msg_2])
        @fact node.interfaces[1].message => msg
        @fact node.interfaces[1].message.value => 1.0
    end

    # Tests on Gaussian messages use the update rules from Korl (2005),
    # "A Factor Graph Approach to Signal Modelling, System Identification and Filtering.", Table 4.1.
    context("AdditionNode should propagate a univariate GaussianMessage") do
        node = AdditionNode()
        context("Univariate GaussianMessage with (m,V) parametrization") do
            inbound_msg_1 = GaussianMessage(m=[1.0], V=[2.0])
            inbound_msg_2 = GaussianMessage(m=[3.0], V=[4.0])
            # Forward message
            msg = calculateMessage!(3, node, [inbound_msg_1, inbound_msg_2, GaussianMessage()])
            @fact node.interfaces[3].message => msg
            @fact node.interfaces[3].message.m => [4.0]
            @fact node.interfaces[3].message.V => reshape([6.0], 1, 1)
            # Backward messages
            for outbound_interface_id = [1,2]
                msg = calculateMessage!(outbound_interface_id, node, [inbound_msg_1, inbound_msg_1, inbound_msg_2])
                @fact node.interfaces[outbound_interface_id].message => msg
                @fact node.interfaces[outbound_interface_id].message.m => [2.0]
                @fact node.interfaces[outbound_interface_id].message.V => reshape([6.0], 1, 1)
            end
        end

        context("Univariate GaussianMessage with (m,W) parametrization") do
            inbound_msg_1 = GaussianMessage(m=[1.0], W=[2.0])
            inbound_msg_2 = GaussianMessage(m=[3.0], W=[4.0])
            # Forward message
            msg = calculateMessage!(3, node, [inbound_msg_1, inbound_msg_2, GaussianMessage()])
            @fact node.interfaces[3].message => msg
            @fact node.interfaces[3].message.m => [4.0]
            @fact node.interfaces[3].message.W => reshape([4.0/3.0], 1, 1)
            # Backward messages
            for outbound_interface_id = [1,2]
                msg = calculateMessage!(outbound_interface_id, node, [inbound_msg_1, inbound_msg_1, inbound_msg_2])
                @fact node.interfaces[outbound_interface_id].message => msg
                @fact node.interfaces[outbound_interface_id].message.m => [2.0]
                @fact node.interfaces[outbound_interface_id].message.W => reshape([4.0/3.0], 1, 1)
            end
        end

        context("Univariate GaussianMessage with different parametrizations") do
            inbound_msg_1 = GaussianMessage(m=[1.0], V=[0.5])
            inbound_msg_2 = GaussianMessage(m=[3.0], W=[4.0])
            # Forward message
            msg = calculateMessage!(3, node, [inbound_msg_1, inbound_msg_2, GaussianMessage()])
            @fact node.interfaces[3].message => msg
            ensureMWParametrization!(msg)
            @fact node.interfaces[3].message.m => [4.0]
            @fact node.interfaces[3].message.W => reshape([4.0/3.0], 1, 1)
            # Backward messages
            for outbound_interface_id = [1,2]
                msg = calculateMessage!(outbound_interface_id, node, [inbound_msg_1, inbound_msg_1, inbound_msg_2])
                ensureMWParametrization!(msg)
                @fact node.interfaces[outbound_interface_id].message => msg
                @fact node.interfaces[outbound_interface_id].message.m => [2.0]
                @fact node.interfaces[outbound_interface_id].message.W => reshape([4.0/3.0], 1, 1)
            end
        end

        context("Univariate GaussianMessage with (xi,V) parametrization") do
            inbound_msg_1 = GaussianMessage(xi=[1.0], V=[2.0])
            inbound_msg_2 = GaussianMessage(xi=[3.0], V=[4.0])
            # Forward message
            msg = calculateMessage!(3, node, [inbound_msg_1, inbound_msg_2, GaussianMessage()])
            @fact node.interfaces[3].message => msg
            @fact maximum(abs(node.interfaces[3].message.xi - [14/6])) < epsilon => true
            @fact node.interfaces[3].message.V => reshape([6.0], 1, 1)
            # Backward messages
            for outbound_interface_id = [1,2]
                msg = calculateMessage!(outbound_interface_id, node, [inbound_msg_1, inbound_msg_1, inbound_msg_2])
                @fact node.interfaces[outbound_interface_id].message => msg
                @fact maximum(abs(node.interfaces[outbound_interface_id].message.xi - [10/6])) < epsilon => true
                @fact node.interfaces[outbound_interface_id].message.V => reshape([6.0], 1, 1)
            end
        end
    end

    # Tests on Gaussian messages use the update rules from Korl (2005),
    # "A Factor Graph Approach to Signal Modelling, System Identification and Filtering.", Table 4.1.
    context("AdditionNode should propagate a multivariate GaussianMessage") do
        node = AdditionNode()
        context("Multivariate GaussianMessage with (m,V) parametrization") do
            mean = [1.0:3.0]
            variance = reshape([4.0, 3.0, 2.0,
                                3.0, 4.0, 3.0,
                                2.0, 3.0, 4.0], 3, 3)
            inbound_msg_1 = GaussianMessage(m=mean, V=variance)
            inbound_msg_2 = GaussianMessage(m=mean, V=variance)
            # Forward message
            msg = calculateMessage!(3, node, [inbound_msg_1, inbound_msg_2, GaussianMessage()])
            @fact node.interfaces[3].message => msg
            @fact node.interfaces[3].message.m => [2.0, 4.0, 6.0]
            @fact node.interfaces[3].message.V => 2.0*variance
            # Backward messages
            for outbound_interface_id = [1,2]
                msg = calculateMessage!(outbound_interface_id, node, [inbound_msg_1, inbound_msg_1, inbound_msg_2])
                @fact node.interfaces[outbound_interface_id].message => msg
                @fact node.interfaces[outbound_interface_id].message.m => [0.0, 0.0, 0.0]
                @fact node.interfaces[outbound_interface_id].message.V => 2.0*variance
            end
        end

        context("Multivariate GaussianMessage with (m,W) parametrization") do
            mean = [1.0:3.0]
            precision = reshape([4.0, 3.0, 2.0,
                                 3.0, 4.0, 3.0,
                                 2.0, 3.0, 4.0], 3, 3)
            inbound_msg_1 = GaussianMessage(m=mean, W=precision)
            inbound_msg_2 = GaussianMessage(m=mean, W=precision)
            # Forward message
            msg = calculateMessage!(3, node, [inbound_msg_1, inbound_msg_2, GaussianMessage()])
            @fact node.interfaces[3].message => msg
            @fact maximum(abs(node.interfaces[3].message.m - [2.0, 4.0, 6.0])) < epsilon => true
            @fact maximum(abs(node.interfaces[3].message.W - reshape([2.0, 1.5, 1.0, 1.5, 2.0, 1.5, 1.0, 1.5, 2.0], 3, 3))) < epsilon => true
            # Backward messages
            for outbound_interface_id = [1,2]
                msg = calculateMessage!(outbound_interface_id, node, [inbound_msg_1, inbound_msg_1, inbound_msg_2])
                @fact node.interfaces[outbound_interface_id].message => msg
                @fact node.interfaces[outbound_interface_id].message.m => [0.0, 0.0, 0.0]
                @fact maximum(abs(node.interfaces[3].message.W - reshape([2.0, 1.5, 1.0, 1.5, 2.0, 1.5, 1.0, 1.5, 2.0], 3, 3))) < epsilon => true
            end
        end

        context("Multivariate GaussianMessage with different parametrizations") do
            mean = [1.0:3.0]
            precision = reshape([4.0, 3.0, 2.0,
                                 3.0, 4.0, 3.0,
                                 2.0, 3.0, 4.0], 3, 3)
            inbound_msg_1 = GaussianMessage(m=mean, W=precision)
            inbound_msg_2 = GaussianMessage(xi=precision*mean, V=inv(precision))
            # Forward message
            msg = calculateMessage!(3, node, [inbound_msg_1, inbound_msg_2, GaussianMessage()])
            ensureMWParametrization!(msg)
            @fact node.interfaces[3].message => msg
            @fact maximum(abs(node.interfaces[3].message.m - [2.0, 4.0, 6.0])) < epsilon => true
            @fact maximum(abs(node.interfaces[3].message.W - reshape([2.0, 1.5, 1.0, 1.5, 2.0, 1.5, 1.0, 1.5, 2.0], 3, 3))) < epsilon => true
            # Backward messages
            for outbound_interface_id = [1,2]
                msg = calculateMessage!(outbound_interface_id, node, [inbound_msg_1, inbound_msg_1, inbound_msg_2])
                ensureMWParametrization!(msg)
                @fact node.interfaces[outbound_interface_id].message => msg
                @fact maximum(abs(node.interfaces[outbound_interface_id].message.m - [0.0, 0.0, 0.0])) < epsilon => true
                @fact maximum(abs(node.interfaces[3].message.W - reshape([2.0, 1.5, 1.0, 1.5, 2.0, 1.5, 1.0, 1.5, 2.0], 3, 3))) < epsilon => true
            end
        end

        context("Multivariate GaussianMessage with (xi,V) parametrization") do
            xi = [1.0:3.0]
            variance = reshape([4.0, 3.0, 2.0,
                                3.0, 4.0, 3.0,
                                2.0, 3.0, 4.0], 3, 3)
            inbound_msg_1 = GaussianMessage(xi=xi, V=variance)
            inbound_msg_2 = GaussianMessage(xi=xi, V=variance)
            # Forward message
            msg = calculateMessage!(3, node, [inbound_msg_1, inbound_msg_2, GaussianMessage()])
            @fact node.interfaces[3].message => msg
            @fact maximum(abs(node.interfaces[3].message.xi - [1.0, 2.0, 3.0])) < epsilon => true
            @fact node.interfaces[3].message.V => 2.0*variance
            # Backward messages
            for outbound_interface_id = [1,2]
                msg = calculateMessage!(outbound_interface_id, node, [inbound_msg_1, inbound_msg_1, inbound_msg_2])
                @fact node.interfaces[outbound_interface_id].message => msg
                @fact node.interfaces[outbound_interface_id].message.xi => [0.0, 0.0, 0.0]
                @fact node.interfaces[outbound_interface_id].message.V => 2.0*variance
            end
        end
    end
end