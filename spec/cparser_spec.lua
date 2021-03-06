local cparser = require "cparser"

local prefix = os.tmpname()
local fname = prefix .. ".h"
os.remove(prefix)

function assert_parser(expected, code)
        local f = assert(io.open(fname, 'w'))
        assert(f:write(code))
        assert(f:close())
        finally(function() os.remove(fname) end)
        local declarations = cparser.parse(fname)
        assert.are.same(expected, declarations)
end

describe("StructDecl", function()
        it("parses an ordinary struct", function()
                assert_parser({ {
                        fields = { {
                            name = "x",
                            type = "int"
                          }, {
                            name = "y",
                            type = "int"
                          } },
                        name = "coordinates",
                        tag = "struct"
                      } }, [[
                  struct coordinates {
                    int x,y;
                  };
                ]])
        end)

        it("parses a struct with an enum declaration inside", function()
                assert_parser({ {
                  fields = { {
                      name = "field1",
                      type = {
                        decl = 2,
                        tag = "decl"
                      }
                    } },
                  name = "rainbow",
                  tag = "struct"
                }, {
                  fields = { {
                      name = "Violet",
                      value = 0
                    }, {
                      name = "Indigo",
                      value = 1
                    }, {
                      name = "Blue",
                      value = 2
                    }, {
                      name = "Green",
                      value = 3
                    }, {
                      name = "Yellow",
                      value = 4
                    }, {
                      name = "Red",
                      value = 5
                    } },
                  name = "Fruit",
                  tag = "enum"
                } }, [[
                        struct rainbow {
                                enum Fruit{Violet, Indigo, Blue, Green, Yellow, Red};
                                enum Fruit field1;
                        };
                ]])
        end)

        it("parses an anonymous struct", function()
                assert_parser({ {
                  fields = { {
                      name = "alpha",
                      type = "char"
                    }, {
                      name = "num",
                      type = "int"
                    } },
                  name = "",
                  tag = "struct"
                }, {
                  name = "var",
                  storage_specifier = "none",
                  tag = "variable",
                  type = {
                    decl = 1,
                    tag = "decl"
                  }
                } }, [[
                        struct {
                                char alpha;
                                int num;
                        } var;
                ]])
        end)

        it("parses a nested struct", function()
                assert_parser({ {
                  fields = { {
                      name = "m1",
                      type = {
                        decl = 2,
                        tag = "decl"
                      }
                    }, {
                      name = "m2",
                      type = {
                        decl = 2,
                        tag = "decl"
                      }
                    }, {
                      name = "pointer",
                      type = {
                        tag = "pointer",
                        type = {
                          decl = 1,
                          tag = "decl"
                        }
                      }
                    }, {
                      name = "double_pointer",
                      type = {
                        tag = "pointer",
                        type = {
                          tag = "pointer",
                          type = {
                            decl = 1,
                            tag = "decl"
                          }
                        }
                      }
                    } },
                  name = "Student",
                  tag = "struct"
                }, {
                  fields = { {
                      name = "physics",
                      type = "int"
                    } },
                  name = "marks",
                  tag = "struct"
                } }, [[
                        struct Student {
                                struct marks{
                                        int physics;        
                                }m1, m2;
                                struct Student *pointer;
                                struct Student **double_pointer;
                        }; 
                ]])
        end)

        it("parses a struct with a function pointer", function()
                assert_parser({ {
                  fields = { {
                      name = "f",
                      type = {
                        fields = { "int" },
                        ret = "int",
                        tag = "function-pointer"
                      }
                    } },
                  name = "mycallback",
                  tag = "struct"
                } }, [[
                        struct mycallback {
                                int (*f)(int);
                        };                         
                ]])
        end)

        it("parses a struct with bit fields", function()
                assert_parser({ {
                  fields = { {
                      bit_field = "true",
                      field_width = 5,
                      name = "x",
                      type = "int"
                    }, {
                      bit_field = "true",
                      field_width = 1,
                      name = "y",
                      type = "int"
                    }, {
                      bit_field = "true",
                      field_width = 2,
                      name = "z",
                      type = "int"
                    } },
                  name = "bits",
                  tag = "struct"
                } }, [[
                        struct bits {
                                int x: 5;
                                int y: 1;
                                int z: 2;
                        };                         
                ]])
        end)

        it("parses a struct containing a named union", function()
                assert_parser({ {
                  fields = { {
                      name = "b",
                      type = "float"
                    }, {
                      name = "uvar1",
                      type = {
                        decl = 2,
                        tag = "decl"
                      }
                    } },
                  name = "st1",
                  tag = "struct"
                }, {
                  fields = { {
                      name = "svar1",
                      type = {
                        decl = 3,
                        tag = "decl"
                      }
                    } },
                  name = "u1",
                  tag = "union"
                }, {
                  fields = { {
                      name = "a",
                      type = "int"
                    } },
                  name = "",
                  tag = "struct"
                } }, [[
                        struct st1 {
                                float b;
                                union u1 {
                                        struct {
                                                int a;
                                        }svar1;
                                }uvar1;
                        };                     
                ]])
        end)

        it("parses a struct containing an unnamed union", function()
                assert_parser({ {
                  fields = { {
                      name = "u",
                      type = {
                        decl = 2,
                        tag = "decl"
                      }
                    }, {
                      name = "b",
                      type = "int"
                    } },
                  name = "st2",
                  tag = "struct"
                }, {
                  fields = { {
                      name = "a",
                      type = "int"
                    } },
                  name = "",
                  tag = "union"
                } }, [[
                        struct st2 {
                                union {
                                        int a;
                                }u;
                                int b;
                        };                    
                ]])
        end)
end)

describe("UnionDecl", function()
        it("parses an ordinary union", function()
                assert_parser( {{
                        fields = { {
                            name = "x",
                            type = "const int"
                          }, {
                            name = "y",
                            type = "const int"
                          } },
                        name = "check",
                        tag = "union"
                      } }, [[
                        union check {
                                const int x, y;
                        };                   
                ]])
        end)

        it("parses an unnamed union", function()
                assert_parser({ {
                  fields = { {
                      name = "a",
                      type = "const int"
                    } },
                  name = "",
                  tag = "union"
                }, {
                  name = "u1",
                  storage_specifier = "none",
                  tag = "variable",
                  type = {
                    decl = 1,
                    tag = "decl"
                  }
                } }, [[
                        union {
                                const int a;
                        }u1;                 
                ]])
        end)

        it("parses a union containing a struct declaration", function()
                assert_parser({ {
                  fields = { {
                      name = "s",
                      type = {
                        tag = "pointer",
                        type = "char"
                      }
                    } },
                  name = "un2",
                  tag = "union"
                }, {
                  fields = { {
                      name = "b",
                      type = "double"
                    } },
                  name = "st1",
                  tag = "struct"
                } }, [[
                        union un2 {
                                struct st1 {
                                        double b;
                                };
                                char *s;
                        };                 
                ]])
        end)

        it("parses an unnamed union enclosing an unnamed struct containing bit fields", function()
                assert_parser({ {
                  fields = { {
                      name = "window1",
                      type = {
                        decl = 2,
                        tag = "decl"
                      }
                    }, {
                      name = "screenval",
                      type = "int"
                    } },
                  name = "",
                  tag = "union"
                }, {
                  fields = { {
                      bit_field = "true",
                      field_width = 8,
                      name = "icon",
                      type = "unsigned int"
                    }, {
                      bit_field = "true",
                      field_width = 4,
                      name = "color",
                      type = "unsigned int"
                    } },
                  name = "",
                  tag = "struct"
                }, {
                  name = "screen",
                  storage_specifier = "none",
                  tag = "variable",
                  type = {
                    n = 25.0,
                    tag = "array",
                    type = {
                      n = 80.0,
                      tag = "array",
                      type = {
                        decl = 1,
                        tag = "decl"
                      }
                    }
                  }
                } }, [[
                        union {                   
                                struct {
                                        unsigned int icon : 8;
                                        unsigned color : 4;
                                } window1;
                                int screenval;
                        }screen[25][80];                  
                ]])
        end)
end)

describe("EnumDecl", function()
        it("parses an ordinary enum", function()
                assert_parser( {{
                        fields = { {
                            name = "Red",
                            value = 0
                          }, {
                            name = "Black",
                            value = 1
                          }, {
                            name = "Yellow",
                            value = 2
                          } },
                        name = "colours",
                        tag = "enum"
                      } }, [[
                        enum colours{Red, Black, Yellow};
                ]])
        end)

        it("parses enum with assigned integral value", function()
                assert_parser( {{
                        fields = { {
                            name = "Mon",
                            value = 99
                          }, {
                            name = "Tue",
                            value = 100
                          }, {
                            name = "Wed",
                            value = 101
                          }, {
                            name = "Thur",
                            value = 102
                          }, {
                            name = "Fri",
                            value = 103
                          }, {
                            name = "Sat",
                            value = 104
                          }, {
                            name = "Sun",
                            value = 105
                          } },
                        name = "week",
                        tag = "enum"
                      } }, [[
                        enum week{Mon=99, Tue, Wed, Thur, Fri, Sat, Sun};
                ]])
        end)

        it("parses enum without a name", function()
                assert_parser( {{
                        fields = { {
                            name = "item1",
                            value = 0
                          }, {
                            name = "item2",
                            value = 1
                          } },
                        name = "",
                        tag = "enum"
                      } }, [[
                        enum {item1, item2};                
                ]])
        end)

        it("parses enum with constant expression", function()
                assert_parser( {{
                        fields = { {
                            name = "A",
                            value = 0
                          }, {
                            name = "B",
                            value = 1
                          }, {
                            name = "C",
                            value = 10
                          }, {
                            name = "D",
                            value = 11
                          }, {
                            name = "E",
                            value = 1
                          }, {
                            name = "F",
                            value = 2
                          }, {
                            name = "G",
                            value = 12
                          } },
                        name = "Foo",
                        tag = "enum"
                      } }, [[
                        enum Foo { A, B, C=10, D, E=1, F, G=F+C};
                ]])
        end)
end)

describe("FunctionDecl", function()
        it("parses a function with storage specifier", function()
                assert_parser( {{
                        inline = false,
                        name = "max",
                        params = { {
                            name = "a",
                            type = "int"
                          }, {
                            name = "b",
                            type = "int"
                          } },
                        ret = "int",
                        storage_specifier = "extern",
                        tag = "function"
                      } }, [[
                        extern int max(int a, int b);
                ]])
        end)

        it("parses a function with return type being pointer to an array", function()
                assert_parser( { {
                  inline = false,
                  name = "foo",
                  params = { {
                      name = "p",
                      type = {
                        tag = "pointer",
                        type = "const void"
                      }
                    } },
                  ret = {
                    tag = "pointer",
                    type = {
                      n = 3.0,
                      tag = "array",
                      type = "int"
                    }
                  },
                  storage_specifier = "none",
                  tag = "function"
                } }, [[
                        int (*foo(const void *p))[3]; 
                ]])
        end)

        it("parses a function of type const double", function()
                assert_parser( {{
                        inline = false,
                        name = "check",
                        params = {},
                        ret = "const double",
                        storage_specifier = "static",
                        tag = "function"
                      } }, [[
                        static double const check(void) { return 0.; } 
                ]])
        end)

        it("parses an inline function", function()
                assert_parser( {{
                        inline = true,
                        name = "sum",
                        params = { {
                            name = "a",
                            type = "int"
                          }, {
                            name = "b",
                            type = "int"
                          } },
                        ret = "int",
                        storage_specifier = "none",
                        tag = "function"
                      } }, [[
                        inline int sum(int a, int b) 
                        {
                                return a + b;
                        }
                ]])
        end)

        it("parses a function definition", function()
                assert_parser( {{
                        inline = false,
                        name = "increment",
                        params = { {
                            name = "a",
                            type = "int"
                          } },
                        ret = "int",
                        storage_specifier = "none",
                        tag = "function"
                      } }, [[
                        int increment(int a){  
                                a++;
                                return a;
                        }
                ]])
        end)

        it("parses a function declaration that contains an anonymous struct definition", function()
                assert_parser({ {
                  fields = { {
                      name = "a",
                      type = "int"
                    } },
                  name = "",
                  tag = "struct"
                }, {
                  inline = false,
                  name = "foo",
                  params = {},
                  ret = {
                    decl = 1,
                    tag = "decl"
                  },
                  storage_specifier = "none",
                  tag = "function"
                } }, [[
                        struct { int a; } foo(void);
                ]])
        end)
end)

describe("TypedefDecl", function()
        it("parses typedefs", function()
                assert_parser({ {
                  tag = "typedef",
                  type = "DRAWF",
                  underlying_type = {
                    fields = { "int", "int" },
                    ret = "void",
                    tag = "function-pointer"
                  }
                }, {
                  fields = { {
                      name = "name",
                      type = {
                        n = 30.0,
                        tag = "array",
                        type = "char"
                      }
                    }, {
                      name = "size",
                      type = "int"
                    }, {
                      name = "year",
                      type = "int"
                    } },
                  name = "club",
                  tag = "struct"
                }, {
                  tag = "typedef",
                  type = "GROUP",
                  underlying_type = {
                    decl = 2,
                    tag = "decl"
                  }
                }, {
                  tag = "typedef",
                  type = "PG",
                  underlying_type = {
                    tag = "pointer",
                    type = {
                      decl = 3,
                      tag = "decl"
                    }
                  }
                }, {
                  tag = "typedef",
                  type = "char_t",
                  underlying_type = "char"
                }, {
                  tag = "typedef",
                  type = "char_p",
                  underlying_type = {
                    tag = "pointer",
                    type = "char"
                  }
                }, {
                  tag = "typedef",
                  type = "fp",
                  underlying_type = {
                    fields = {},
                    ret = "char",
                    tag = "function-pointer"
                  }
                } }, [[
                        typedef void DRAWF( int, int );
                        typedef struct club
                        {
                                char name[30];
                                int size, year;
                        } GROUP;
                        
                        typedef GROUP *PG;
                        
                        typedef char char_t, *char_p, (*fp)(void);
                ]])
        end)
end)

describe("VarDecl", function()
        it("parses variable with storage class", function()
                assert_parser( { {
                  name = "list",
                  storage_specifier = "static",
                  tag = "variable",
                  type = {
                    n = 20.0,
                    tag = "array",
                    type = "int"
                  }
                } }, [[
                        static int list[20];
                ]])
        end)

        it("parses an array of pointers", function()
                assert_parser( { {
                  name = "aptr",
                  storage_specifier = "none",
                  tag = "variable",
                  type = {
                    n = 10.0,
                    tag = "array",
                    type = {
                      tag = "pointer",
                      type = "int"
                    }
                  }
                } }, [[
                        int *aptr[10];
                ]])
        end)

        it("parses a struct variable", function()
                assert_parser({ {
                  fields = { {
                      name = "a",
                      type = "int"
                    } },
                  name = "st1",
                  tag = "struct"
                }, {
                  name = "st1_instance",
                  storage_specifier = "none",
                  tag = "variable",
                  type = {
                    decl = 1,
                    tag = "decl"
                  }
                } }, [[
                        struct st1 {
                                int a;
                        };
                        
                        struct st1 st1_instance = {10};
                ]])
        end)

        it("parses a union variable", function()
                assert_parser({ {
                  fields = { {
                      name = "s",
                      type = {
                        tag = "pointer",
                        type = "char"
                      }
                    } },
                  name = "un1",
                  tag = "union"
                }, {
                  name = "un1_instance",
                  storage_specifier = "none",
                  tag = "variable",
                  type = {
                    decl = 1,
                    tag = "decl"
                  }
                } }, [[
                        union un1 {
                                char *s;
                        }un1_instance;
                ]])
        end)
end)