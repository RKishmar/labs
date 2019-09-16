library verilog;
use verilog.vl_types.all;
entity lab2_6 is
    generic(
        WIDTH           : vl_notype
    );
    port(
        clk_i           : in     vl_logic;
        srst_i          : in     vl_logic;
        data_i          : in     vl_logic_vector;
        data_val_i      : in     vl_logic;
        data_val_o      : out    vl_logic;
        data_o          : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of WIDTH : constant is 5;
end lab2_6;
