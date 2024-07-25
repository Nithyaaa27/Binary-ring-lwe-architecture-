module RingLWE #(parameter N = 4, parameter Q = 2) (
    input logic clk,
    input logic rst,
    input logic [Q-1:0] r2, // 0-degree polynomial for r2
    input logic [Q-1:0] e1, // 0-degree polynomial for e1
    input var [N-1:0][Q-1:0] r1,
    input var [N-1:0][Q-1:0] a,
    input var [N-1:0][Q-1:0] message,
    input var [N-1:0][Q-1:0] e2,
    input var [N-1:0][Q-1:0] e3,
    input logic start,
    output var [N-1:0][Q-1:0] ciphertext1,
    output var [N-1:0][Q-1:0] ciphertext2,
    output var [N-1:0][Q-1:0] decoded_message,
    output var [N-1:0][Q-1:0] public_key_p
);

    // Internal signals for key generation
    logic [N-1:0][Q-1:0] p;

    // Internal signals for encryption
    logic [N-1:0][Q-1:0] c1, c2;

    // Key generation process
    task key_generation();
        // Compute public key p
        p = polynomial_sub(r1, polynomial_mult_const(a, r2));
    endtask

    // Encryption process
    task encryption(input logic [N-1:0][Q-1:0] m);
        // Compute ciphertexts c1 and c2
        c1 = polynomial_add(polynomial_mult_const(a, e1), e2);
        c2 = polynomial_add(polynomial_add(polynomial_mult_const(p, e1), e3), m);
    endtask

    // Decryption process
    task decryption(input logic [N-1:0][Q-1:0] c1, c2, output logic [N-1:0][Q-1:0] m);
        // Compute decoded message
        m = polynomial_add(polynomial_mult_const(c1, r2), c2);
    endtask

    // Polynomial addition (modulo Q)
    function logic [N-1:0][Q-1:0] polynomial_add(
        input logic [N-1:0][Q-1:0] poly1,
        input logic [N-1:0][Q-1:0] poly2
    );
        logic [N-1:0][Q-1:0] result;
        for (int i = 0; i < N; i++) begin
            result[i] = (poly1[i] + poly2[i]) % Q;
        end
        return result;
    endfunction

    // Polynomial subtraction (modulo Q)
    function logic [N-1:0][Q-1:0] polynomial_sub(
        input logic [N-1:0][Q-1:0] poly1,
        input logic [N-1:0][Q-1:0] poly2
    );
        logic [N-1:0][Q-1:0] result;
        for (int i = 0; i < N; i++) begin
            result[i] = (poly1[i] - poly2[i] + Q) % Q; // Add Q to avoid negative values
        end
        return result;
    endfunction

    // Polynomial multiplication with a constant (modulo Q)
    function logic [N-1:0][Q-1:0] polynomial_mult_const(
        input logic [N-1:0][Q-1:0] poly,
        input logic [Q-1:0] constant
    );
        logic [N-1:0][Q-1:0] result;
        for (int i = 0; i < N; i++) begin
            result[i] = (poly[i] * constant) % Q;
        end
        return result;
    endfunction

    // Main sequential process
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic (if any)
        end else if (start) begin
            // Perform key generation
            key_generation();
            
            // Output public key
            public_key_p <= p;
            
            // Perform encryption
            encryption(message);
            
            // Output ciphertexts
            ciphertext1 <= c1;
            ciphertext2 <= c2;
            
            // Perform decryption
            decryption(c1, c2, decoded_message);
        end
    end
endmodule
