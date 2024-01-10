%%Declaring the default values for variables
 generatorTemp = 30;
 turbineTemp = 30;
 transformatorTemp = 30;

 generatorFan = 0;
 transformatorFan = 0;
 turbineFan = 0;
 
 gate = 100;
 current = 275 * gate/100;
 phaseAngle = 10;

 apparentPower = (sqrt(3)*current*6600)/10^6;
%% Declaring all nodes
%Config för OPC UA server
uaClient = opcua('localhost', 62640);
connect(uaClient);
topNodes = uaClient.Namespace;
ServerChildren = topNodes(4).Children;

%Generator ström
Generator_current1 = opcuanode(2,'Generator_current1',uaClient);
Generator_current2 = opcuanode(2,'Generator_current2',uaClient);
Generator_current3 = opcuanode(2,'Generator_current3',uaClient);

%Generator spänning
Generator_voltage1 = opcuanode(2,'Generator_voltage1',uaClient);
Generator_voltage2 = opcuanode(2,'Generator_voltage2',uaClient);
Generator_voltage3 = opcuanode(2,'Generator_voltage3',uaClient);

%Generator övriga signaler
Generator_phaseAngle = opcuanode(2,'Generator_phaseAngle',uaClient);
Generator_oil = opcuanode(2,'Generator_oil',uaClient);
Generator_temperature = opcuanode(2,'Generator_temperature',uaClient);
Generator_fan = opcuanode(2,'Generator_fan',uaClient);
Generator_manualControl = opcuanode(2,'Generator_manualControl',uaClient);

%Turbin övriga signaler
turbine_rotationSpeed = opcuanode(2,'Turbine_rotationSpeed',uaClient);
turbine_oil = opcuanode(2,'Turbine_oil',uaClient);
turbine_temperature = opcuanode(2,'Turbine_temperature',uaClient);
turbine_fan = opcuanode(2,'Turbine_fan',uaClient);
turbine_gate = opcuanode(2,'Turbine_gate',uaClient);
turbine_manualControl = opcuanode(2,'Turbine_manualControl',uaClient);

%Transformator signaler
Transformator_temperature = opcuanode(2,'Transformer_temperature',uaClient);
Transformator_fan = opcuanode(2,'Transformer_fan',uaClient);
Transformator_manualControl = opcuanode(2,'Transformer_manualControl',uaClient);

%Effekt
Power_apparent = opcuanode(2,'Power_apparent',uaClient);
Power_active = opcuanode(2,'Power_active',uaClient);
Power_reactive = opcuanode(2,'Power_reactive',uaClient);


%Skriv värden til taggar.
 writeValue(uaClient,turbine_temperature,70);
 writeValue(uaClient,turbine_oil,90);
 writeValue(uaClient,turbine_rotationSpeed,750);

 writeValue(uaClient,Generator_phaseAngle,10);
 writeValue(uaClient,Generator_oil,80);

 writeValue(uaClient,Generator_temperature,generatorTemp);
 
 writeValue(uaClient,turbine_gate,100);


%% To be run continously 
t = 0;
while (t < 10)
   % phaseAngle = readValue(uaClient,Generator_phaseAngle); % Writes the current node value for the phaseAngle to the variable
    gate = readValue(uaClient,turbine_gate);
    current = 275 * gate/100;
    apparentPower = (sqrt(3)*current*6600)/10^6;

    sine1 = sin(2*pi*t) ;               %sine wave for phase 1
    sine2 = sin(2*pi*t - ((2*pi)/3));   %sine wave for phase 2
    sine3 = sin(2*pi*t - ((4*pi)/3));   %sine wave for phase 3

    writeValue(uaClient,Generator_current1,current*sine1);
    writeValue(uaClient,Generator_voltage1,6600*sine1);

    writeValue(uaClient,Generator_current2,current*sine2);
    writeValue(uaClient,Generator_voltage2,6600*sine2);

    writeValue(uaClient,Generator_current3,current*sine3);
    writeValue(uaClient,Generator_voltage3,6600*sine3);
   
    generatorManualControl = readValue(uaClient, Generator_manualControl);

    %Temperature rise for generator
    generatorTemp = readValue(uaClient,Generator_temperature);
    generatorFan = readValue(uaClient,Generator_fan);
    phaseAngle = readValue(uaClient,Generator_phaseAngle);
    phaseAngleCorrection = 0.01;
    %If the manual control for the generator is disabled, control the variables automaticly 
    if(generatorManualControl == "false")
        generatorFan = generatorFan + (generatorTemp-50)/4;
        if(generatorFan>100)
            generatorFan = 100;
        elseif(generatorFan<0)
            generatorFan = 0;
        end    
        writeValue(uaClient,Generator_fan,generatorFan);
        phaseAngleCorrection = phaseAngleCorrection - (phaseAngle-5)/10;
    end

    generatorTemp = generatorTemp + 0.1 - 0.12*(generatorFan/100);
    writeValue(uaClient,Generator_temperature,generatorTemp);
    
    phaseAngle = phaseAngle + phaseAngleCorrection;
    writeValue(uaClient,Generator_phaseAngle,phaseAngle);

    writeValue(uaClient,Power_apparent,apparentPower);
    writeValue(uaClient,Power_active,apparentPower * cos(phaseAngle*pi/180));
    writeValue(uaClient,Power_reactive,apparentPower * sin(phaseAngle*pi/180));


    %Temperature rise for tuirbine
    turbineTemp = readValue(uaClient,turbine_temperature);
    turbineFan = readValue(uaClient,turbine_fan);

    turbineManualControl = readValue(uaClient,turbine_manualControl);
    if(turbineManualControl == "false")
        turbineFan = turbineFan + (turbineTemp-50)/4;
        if(turbineFan>100)
            turbineFan = 100;
        elseif(turbineFan<0)
            turbineFan = 0;
        end    
        writeValue(uaClient,turbine_fan,turbineFan);
    end
    turbineTemp = turbineTemp + 0.1 - 0.12*(turbineFan/100);
    writeValue(uaClient,turbine_temperature,turbineTemp);


    %Temperature rise for transformator
    transformatorTemp = readValue(uaClient,Transformator_temperature);
    transformatorFan = readValue(uaClient,Transformator_fan);
    transformatorManualControl = readValue(uaClient,Transformator_manualControl);
    if(transformatorManualControl == "false")
        transformatorFan = transformatorFan + (transformatorTemp-50)/4;
        if(transformatorFan>100)
            transformatorFan = 100;
        elseif(transformatorFan<0)
            transformatorFan = 0;
        end    
        writeValue(uaClient,Transformator_fan,transformatorFan);
    end

    transformatorTemp = transformatorTemp + 0.1 - 0.12*(transformatorFan/100);
    writeValue(uaClient,Transformator_temperature,transformatorTemp);
    
    t = t + 0.01;
    pause(0.1);
end

disconnect(uaClient);
