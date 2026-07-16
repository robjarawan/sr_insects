# Flow test graphs

- Dynamic flow test additional documentation/explanation: https://github.com/MetPX/sr_insects/blob/main/dynamic_flow/doc/Explanation.rst

- Legend
    - Boxes highlighted in $\color{red}{\text{red}}$: Directories where data is downloaded/sent locally during the test.
    - Diamonds highlighted in $\color{blue}{\text{blue}}$: Exchanges used on local/public brokers.

## Static flow , Flakey broker , Restart server

NOTE 1: Flakey broker and restart server tests are the same **with the exception of the `subscribe/mirror_f80` configuration being missing**.

```mermaid

flowchart TD

   %% Bundled CFlow components
   subgraph CFlow ["SarraC Data Flow"]
    xcsarra{{xcsarra}}
    xcvan{{xcvan00,01}}
    xcpublic{{xcpublic}}
    xs_tsource_shim{{xs_tsource_shim}}
    cpost_config1([cpost/pelle_dd1.conf])
    cpost_config2([cpost/pelle_dd2.conf])
    cpost_config3([cpost/veille_f34.conf])
    cpump_config1([cpump/xvan_f14.conf])
    cpump_config2([cpump/xvan_f15.conf])
    post_shim_config([post/shim_f63.conf])
    subscribe_config7(["subscribe/cdnld_f21.conf"])
    subscribe_config8(["subscribe/mirror_f80.conf"])
    subscribe_config9(["subscribe/cfile_f44.conf"])
    subscribe_data7[$HOME/sarra_devdocroot/cfr]
    subscribe_data8[$HOME/sarra_devdocroot/mirror]
    subscribe_data9[$HOME/sarra_devdocroot/cfile]
   end

    %% Non-CFlow components
    %% Directories
    initial_data[$HOME/sr_insects/samples/data]
    sarra_data[$HOME/sarra_devdocroot/$YYYY$MM$DD]
    subscribe_data1[$HOME/sarra_devdocroot/downloaded_by_sub_amqp]
    subscribe_data2[$HOME/sarra_devdocroot/downloaded_by_sub_rabbitmqtt]
    subscribe_data3[$HOME/sarra_devdocroot/downloaded_by_sub_cp]
    subscribe_data4[$HOME/sarra_devdocroot/downloaded_by_sub_u]
    subscribe_data5[$HOME/sarra_devdocroot/posted_by_srpost_test2]
    subscribe_data6[$HOME/sarra_devdocroot/recd_by_srpoll_test1]
    shim_data1[$HOME/sarra_devdocroot/posted_by_shim]
    shim_data2[$HOME/sarra_devdocroot/linked_by_shim]
    sender_data[$HOME/sarra_devdocroot/sent_by_tsource2send]

    subgraph Scripts ["Scripts"]
      post_script([flow_post.sh])
    end

    %% Configs
    post_config1([post/t_dd1_f00.conf])
    post_config2([post/t_dd2_f00.conf])
    post_config3([post/test2_f61.conf])
    cpost_config1([cpost/pelle_dd1.conf])
    cpost_config2([cpost/pelle_dd2.conf])
    cpost_config3([cpost/veille_f34.conf])
    cpump_config1([cpump/xvan_f14.conf])
    cpump_config2([cpump/xvan_f15.conf])
    post_shim_config([post/shim_f63.conf])
    poll_config(["poll/sftp_f62.conf"])
    sarra_config(["sarra/download_f20.conf"])
    subscribe_config1(["subscribe/amqp_f30.conf"])
    subscribe_config2(["subscribe/rabbitmqtt_f31.conf"])
    subscribe_config3(["subscribe/u_sftp_f60.conf"])
    subscribe_config4(["subscribe/cp_f61.conf"])
    subscribe_config5(["subscribe/ftp_f70.conf"])
    subscribe_config6(["subscribe/q_f71.conf"])
    watch_config(["watch/f40.conf"])
    sender_config(["sender/tsource2send_f50.conf"])
    shovel_config(["shovel/rabbitmqtt_f22.conf"])

    %% Exchanges
    xsarra{{xsarra}}
    xflow_public{{xflow_public}}
    xs_tsource{{xs_tsource}}
    xs_tsource_output{{xs_tsource_output}}
    xs_mqtt_public{{xs_mqtt_public}}
    xs_tsource_post{{xs_tsource_post}}
    xs_tsource_poll{{xs_tsource_poll}}


    %% Data flow
    initial_data --> post_config1
    initial_data --> post_config2
    initial_data --> cpost_config1
    initial_data --> cpost_config2
    post_config1 -->|AMQP| xsarra
    post_config2 -->|AMQP| xsarra
    cpost_config1 -->|AMQP| xcvan
    cpost_config2 -->|AMQP| xcvan
    xcvan --> cpump_config1
    xcvan --> cpump_config2
    cpump_config1 -->|AMQP| xcsarra
    cpump_config2 -->|AMQP| xcsarra
    post_script -->|invoke,shim| post_config3  
    post_script -->|cp| shim_data1
    post_script -->|ln -s| shim_data2
    post_script -->|invoke,shim| post_shim_config
    post_shim_config --> |AMQP| xs_tsource_shim
    xs_tsource_shim --> subscribe_config8
    subscribe_config8 -->|HTTP, download| subscribe_data8
    xcsarra --> subscribe_config7
    subscribe_config7 -->|HTTP, download| subscribe_data7
    subscribe_data7 --> cpost_config3
    cpost_config3 -->|AMQP| xcpublic
    xcpublic --> subscribe_config9
    subscribe_config9 -->|file:// transfer, download| subscribe_data9
    xsarra --> sarra_config
    shim_data1 ---> post_shim_config
    shim_data2 ---> post_shim_config
    sarra_config-->|HTTP, download| sarra_data
    sarra_config -->|AMQP| xflow_public
    subscribe_config1 -->|HTTP, download| subscribe_data1
    xflow_public --> subscribe_config1
    subscribe_data1 -->|Watch| watch_config
    watch_config -->|AMQP| xs_tsource
    xs_tsource --> sender_config 
    sender_config -->|SFTP,send| sender_data  
    sender_data ---> post_config3 
    sender_data -->|poll| poll_config  
    post_config3 -->|AMQP| xs_tsource_post
    poll_config -->|AMQP| xs_tsource_poll
    xs_tsource_post --> subscribe_config5
    xs_tsource_poll --> subscribe_config6
    subscribe_config5 -->|FTP, download| subscribe_data5
    subscribe_config6 -->|SFTP, download| subscribe_data6
    sender_config -->|AMQP| xs_tsource_output
    xs_tsource_output --> subscribe_config4
    xs_tsource_output --> subscribe_config3
    subscribe_config3 -->|SFTP, download| subscribe_data3
    subscribe_config4 -->|cp command, download| subscribe_data4
    xs_tsource --> shovel_config 
    shovel_config -->|AMQP| xs_mqtt_public
    xs_mqtt_public --> subscribe_config2
    subscribe_config2 -->|HTTP, download| subscribe_data2

    classDef redMatch fill:#ffcccc,stroke:#ff0000,stroke-width:2px,color:#ff0000;
    class shim_data1,shim_data2,subscribe_data1,subscribe_data2,subscribe_data3,subscribe_data4,subscribe_data5,subscribe_data6,subscribe_data7,subscribe_data8,subscribe_data9,sarra_data,sender_data redMatch;
    classDef blueMatch fill:#a2d2ff,stroke:#8ecae6,stroke-width:2px,color:#003049;
    class xcsarra,xcpublic,xs_tsource_shim,xcvan,xsarra,xwinnow00,xwinnow01,xflow_public,xs_tsource,xs_tsource_output,xs_tsource_post,xs_tsource_poll,xs_tsource_clean_f90,xs_tsource_clean_f92,xs_mqtt_public blueMatch
```

## Dynamic flow

NOTE 1: `flowcb/filter/pclean_f90.py` and `flowcb/filter/pclean_f92.py` plugins call `flowcb/pclean.py` which inherently looks at all the directories that download/send data. These plugins are all included in the sr3 source code.

```mermaid

flowchart TD

   %% Bundled CFlow components
   subgraph CFlow ["SarraC Data Flow"]
    xcsarra{{xcsarra}}
    xcvan{{xcvan00,01}}
    xcpublic{{xcpublic}}
    xs_tsource_shim{{xs_tsource_shim}}
    cpump_config3([cpump/pelle_dd1.conf])
    cpump_config4([cpump/pelle_dd2.conf])
    cpost_config3([cpost/veille_f34.conf])
    cpump_config1([cpump/xvan_f14.conf])
    cpump_config2([cpump/xvan_f15.conf])
    post_shim_config([post/shim_f63.conf])
    subscribe_config7(["subscribe/cdnld_f21.conf"])
    subscribe_config8(["subscribe/cclean_f91.conf"])
    subscribe_config9(["subscribe/cfile_f44.conf"])
    subscribe_data7[$HOME/sarra_devdocroot/cfr]
    subscribe_data8[$HOME/sarra_devdocroot/mirror]
    subscribe_data9[$HOME/sarra_devdocroot/cfile]
   end

   subgraph HPFX ["HPFX server"]
    initial_data[https://hpfx.collab.science.gc.ca/$YYYY$MM$DD/WXO-DD/]
    xpublic{{xpublic}}
   end

   subgraph Scripts ["Scripts"]
     post_script([flow_post.sh])
   end

    %% Non-CFlow components
    %% Directories
    sarra_data[$HOME/sarra_devdocroot/$YYYY$MM$DD]
    subscribe_data1[$HOME/sarra_devdocroot/downloaded_by_sub_amqp]
    subscribe_data2[$HOME/sarra_devdocroot/downloaded_by_sub_rabbitmqtt]
    subscribe_data3[$HOME/sarra_devdocroot/downloaded_by_sub_cp]
    subscribe_data4[$HOME/sarra_devdocroot/downloaded_by_sub_u]
    subscribe_data5[$HOME/sarra_devdocroot/posted_by_srpost_test2]
    subscribe_data6[$HOME/sarra_devdocroot/recd_by_srpoll_test1]
    shim_data[$HOME/sarra_devdocroot/posted_by_shim]
    sender_data[$HOME/sarra_devdocroot/sent_by_tsource2send]

    %% Configs
    post_config3([post/test2_f61.conf])
    cpost_config3([cpost/veille_f34.conf])
    cpump_config1([cpump/xvan_f14.conf])
    cpump_config2([cpump/xvan_f15.conf])
    post_shim_config([post/shim_f63.conf])
    poll_config(["poll/f62.conf"])
    sarra_config(["sarra/download_f20.conf"])
    subscribe_config1(["subscribe/amqp_f30.conf"])
    subscribe_config2(["subscribe/rabbitmqtt_f31.conf"])
    subscribe_config3(["subscribe/u_sftp_f60.conf"])
    subscribe_config4(["subscribe/cp_f61.conf"])
    subscribe_config5(["subscribe/ftp_f70.conf"])
    subscribe_config6(["subscribe/q_f71.conf"])
    watch_config(["watch/f40.conf"])
    sender_config(["sender/tsource2send_f50.conf"])
    winnow_config1([winnow/t00_f10.conf])
    winnow_config2([winnow/t01_f10.conf])
    shovel_config1([shovel/t_dd1_f00.conf])
    shovel_config2([shovel/t_dd2_f00.conf])
    shovel_config3(["shovel/rabbitmqtt_f22.conf"])
    shovel_config4(["shovel/pclean_f90.conf\nCalls the plugin filter/pclean_f90.py\nChecks if copies of all files exists in all directories"])
    shovel_config5(["shovel/pclean_f92.conf\nCalls the plugin filter/pclean_f92.py\nIt will remove all files in all directories that have downloaded/sent data."])

    %% Exchanges
    xsarra{{xsarra}}
    xwinnow00{{xwinnow00}}
    xwinnow01{{xwinnow01}}
    xflow_public{{xflow_public}}
    xs_tsource{{xs_tsource}}
    xs_tsource_output{{xs_tsource_output}}
    xs_mqtt_public{{xs_mqtt_public}}
    xs_tsource_post{{xs_tsource_post}}
    xs_tsource_poll{{xs_tsource_poll}}
    xs_tsource_clean_f90{{xs_tsource_clean_f90}}
    xs_tsource_clean_f92{{xs_tsource_clean_f92}}


    %% Data flow
    initial_data -->|AMQP| xpublic
    xpublic -->|AMQP| shovel_config1
    xpublic -->|AMQP| shovel_config2
    xpublic -->|AMQP| cpump_config3
    xpublic -->|AMQP| cpump_config4
    shovel_config1 -->|AMQP| xwinnow00
    shovel_config1 -->|AMQP| xwinnow01
    shovel_config2 -->|AMQP| xwinnow00
    shovel_config2 -->|AMQP| xwinnow01
    xwinnow00 ---> winnow_config1
    xwinnow01 ---> winnow_config2
    winnow_config1 --->|AMQP| xsarra
    winnow_config2 --->|AMQP| xsarra
    cpump_config3 -->|AMQP| xcvan
    cpump_config4 -->|AMQP| xcvan
    xcvan --> cpump_config1
    xcvan --> cpump_config2
    cpump_config1 -->|AMQP| xcsarra
    cpump_config2 -->|AMQP| xcsarra
    post_shim_config --> |AMQP| xs_tsource_shim
    xcsarra --> subscribe_config7
    xcpublic --> subscribe_config8
    subscribe_config7 -->|HTTP, download| subscribe_data7
    subscribe_data7 --> cpost_config3
    cpost_config3 -->|AMQP| xcpublic
    xcpublic --> subscribe_config9
    subscribe_config9 -->|file:// transfer, download| subscribe_data9
    subscribe_config8 -->|HTTP, download| subscribe_data8
    xsarra --> sarra_config
    sarra_config-->|HTTP, download| sarra_data
    shim_data ---> post_shim_config
    post_script -->|invoke,shim| post_config3
    post_script -->|cp| shim_data
    post_script -->|invoke,shim| post_shim_config
    sarra_config -->|AMQP| xflow_public
    xflow_public --> subscribe_config1
    subscribe_config1 -->|HTTP, download| subscribe_data1
    subscribe_data1 -->|Watch| watch_config
    watch_config -->|AMQP| xs_tsource
    xs_tsource --> sender_config 
    sender_config -->|SFTP,send| sender_data
    sender_data ---> post_config3 
    sender_data -->|poll| poll_config  
    poll_config -->|AMQP| xs_tsource_poll
    post_config3 -->|AMQP| xs_tsource_post
    xs_tsource_post --> subscribe_config5
    xs_tsource_poll --> subscribe_config6
    subscribe_config5 -->|FTP, download| subscribe_data5
    subscribe_config6 -->|SFTP, download| subscribe_data6
    sender_config -->|AMQP,post| xs_tsource_output
    xs_tsource_output --> subscribe_config3
    xs_tsource_output --> subscribe_config4
    subscribe_config3 -->|SFTP, download| subscribe_data3
    subscribe_config4 -->|cp command, download| subscribe_data4
    xs_tsource --> shovel_config3
    xs_tsource --> shovel_config4
    shovel_config4 --->|AMQP| xs_tsource_clean_f90
    xs_tsource_clean_f90 --> shovel_config5
    shovel_config5 --->|AMQP| xs_tsource_clean_f92
    shovel_config3 -->|AMQP| xs_mqtt_public
    xs_mqtt_public --> subscribe_config2
    subscribe_config2 -->|HTTP, download| subscribe_data2

    classDef redMatch fill:#ffcccc,stroke:#ff0000,stroke-width:2px,color:#ff0000;
    class shim_data,subscribe_data1,subscribe_data2,subscribe_data3,subscribe_data4,subscribe_data5,subscribe_data6,subscribe_data7,subscribe_data8,subscribe_data9,sarra_data,sender_data redMatch;
    classDef blueMatch fill:#a2d2ff,stroke:#8ecae6,stroke-width:2px,color:#003049;
    class xpublic,xcsarra,xcpublic,xs_tsource_shim,xcvan,xsarra,xwinnow00,xwinnow01,xflow_public,xs_tsource,xs_tsource_output,xs_tsource_post,xs_tsource_poll,xs_tsource_clean_f90,xs_tsource_clean_f92,xs_mqtt_public blueMatch
```
