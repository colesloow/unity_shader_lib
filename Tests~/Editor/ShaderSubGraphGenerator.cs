#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEditor.Graphing;
using UnityEditor.ShaderGraph;
using UnityEngine;

namespace Coleslow.ShaderLib.EditorTools
{
    // Generates .shadersubgraph assets that wrap com.coleslow.shaderlib HLSL functions.
    // Each subgraph holds one Custom Function node (File mode) pointing at a wrapper
    // file, with its ports mirrored to subgraph inputs and outputs.
    //
    // Uses internal Shader Graph API, so it is version-fragile by design. Tested
    // against Unity 6000.5 / Shader Graph 17.5. Failures per subgraph are isolated
    // and logged; extend the Specs table to cover more domains.
    public static class ShaderSubGraphGenerator
    {
        const string PackageRoot = "Packages/com.coleslow.shaderlib";
        const string WrappersDir = PackageRoot + "/ShaderGraph/Wrappers";
        const string OutputDir = PackageRoot + "/ShaderGraph/Nodes";

        enum PortType { Float, Vector2, Vector3, Vector4, Matrix4 }

        readonly struct Port
        {
            public readonly string Name;
            public readonly PortType Type;
            public Port(string name, PortType type) { Name = name; Type = type; }
        }

        sealed class Spec
        {
            public string Name;
            public string Domain;
            public string Wrapper; // file name inside WrappersDir
            public Port[] Inputs;
            public Port[] Outputs;
        }

        // Port names MUST match the wrapper function parameter names exactly:
        // Shader Graph builds the call from the slot names.
        static readonly Spec[] Specs =
        {
            new Spec { Name = "Hash12", Domain = "Noise", Wrapper = "NoiseSG.hlsl",
                Inputs = new[] { new Port("UV", PortType.Vector2) },
                Outputs = new[] { new Port("Out", PortType.Float) } },

            new Spec { Name = "Hash13", Domain = "Noise", Wrapper = "NoiseSG.hlsl",
                Inputs = new[] { new Port("P", PortType.Vector3) },
                Outputs = new[] { new Port("Out", PortType.Float) } },

            new Spec { Name = "Hash22", Domain = "Noise", Wrapper = "NoiseSG.hlsl",
                Inputs = new[] { new Port("P", PortType.Vector2) },
                Outputs = new[] { new Port("Out", PortType.Vector2) } },

            new Spec { Name = "Hash33", Domain = "Noise", Wrapper = "NoiseSG.hlsl",
                Inputs = new[] { new Port("P", PortType.Vector3) },
                Outputs = new[] { new Port("Out", PortType.Vector3) } },

            new Spec { Name = "Fbm", Domain = "Noise", Wrapper = "NoiseSG.hlsl",
                Inputs = new[] { new Port("P", PortType.Vector3) },
                Outputs = new[] { new Port("Out", PortType.Float) } },

            new Spec { Name = "Fbm2D", Domain = "Noise", Wrapper = "NoiseSG.hlsl",
                Inputs = new[] { new Port("UV", PortType.Vector2) },
                Outputs = new[] { new Port("Out", PortType.Float) } },

            new Spec { Name = "FbmWarped", Domain = "Noise", Wrapper = "NoiseSG.hlsl",
                Inputs = new[] { new Port("P", PortType.Vector3), new Port("WarpAmount", PortType.Float) },
                Outputs = new[] { new Port("Out", PortType.Float) } },

            new Spec { Name = "Voronoi2D", Domain = "Noise", Wrapper = "NoiseSG.hlsl",
                Inputs = new[] { new Port("UV", PortType.Vector2), new Port("Jitter", PortType.Float) },
                Outputs = new[] { new Port("F1", PortType.Float), new Port("F2", PortType.Float) } },
        };

        [MenuItem("Coleslow/Generate SubGraphs")]
        public static void Generate()
        {
            int ok = 0, fail = 0;
            foreach (var spec in Specs)
            {
                try
                {
                    GenerateOne(spec);
                    ok++;
                }
                catch (Exception e)
                {
                    fail++;
                    Debug.LogError($"[SubGraphGen] '{spec.Name}' failed: {e.Message}\n{e}");
                }
            }
            AssetDatabase.Refresh();
            Debug.Log($"[SubGraphGen] done: {ok} generated, {fail} failed");
        }

        static void GenerateOne(Spec spec)
        {
            string wrapperPath = $"{WrappersDir}/{spec.Wrapper}";
            string wrapperGuid = AssetDatabase.AssetPathToGUID(wrapperPath);
            if (string.IsNullOrEmpty(wrapperGuid))
                throw new Exception($"wrapper asset not found: {wrapperPath}");

            var graph = new GraphData();
            SetMember(graph, "isSubGraph", true, "m_IsSubGraph");
            graph.path = $"Coleslow/{spec.Domain}";

            // --- subgraph inputs: blackboard property + property node feeding the call ---
            var propNodes = new List<PropertyNode>();
            foreach (var p in spec.Inputs)
            {
                AbstractShaderProperty prop = MakeProperty(p.Type);
                prop.displayName = p.Name;
                prop.overrideReferenceName = "_" + p.Name;
                AddGraphInput(graph, prop);

                var pn = new PropertyNode();
                graph.AddNode(pn);
                SetMember(pn, "property", prop, "m_Property");
                propNodes.Add(pn);
            }

            // --- custom function node ---
            var cfn = new CustomFunctionNode();
            graph.AddNode(cfn);
            SetMember(cfn, "sourceType", HlslSourceType.File, "m_SourceType");
            SetMember(cfn, "functionName", spec.Name, "m_FunctionName");
            SetMember(cfn, "functionSource", wrapperGuid, "m_FunctionSource");

            int slotId = 0;
            var cfnInputIds = new List<int>();
            foreach (var p in spec.Inputs)
            {
                cfn.AddSlot(MakeSlot(slotId, p, SlotType.Input));
                cfnInputIds.Add(slotId++);
            }
            var cfnOutputIds = new List<int>();
            foreach (var p in spec.Outputs)
            {
                cfn.AddSlot(MakeSlot(slotId, p, SlotType.Output));
                cfnOutputIds.Add(slotId++);
            }
            cfn.RemoveSlotsNameNotMatching(Enumerable.Range(0, slotId).ToList(), true);

            // --- subgraph output node ---
            var outNode = new SubGraphOutputNode();
            graph.AddNode(outNode);
            foreach (var s in outNode.GetInputSlots<MaterialSlot>().ToList())
                outNode.RemoveSlot(s.id);

            var outSlotIds = new List<int>();
            int oid = 1;
            foreach (var p in spec.Outputs)
            {
                var slot = MakeSlot(oid, p, SlotType.Input);
                outNode.AddSlot(slot);
                outSlotIds.Add(oid);
                oid++;
            }

            // --- edges ---
            for (int i = 0; i < spec.Inputs.Length; i++)
                graph.Connect(propNodes[i].GetSlotReference(PropertyNode.OutputSlotId),
                              cfn.GetSlotReference(cfnInputIds[i]));
            for (int i = 0; i < spec.Outputs.Length; i++)
                graph.Connect(cfn.GetSlotReference(cfnOutputIds[i]),
                              outNode.GetSlotReference(outSlotIds[i]));

            TryCall(graph, "OnEnable");
            graph.ValidateGraph();

            string dir = $"{OutputDir}/{spec.Domain}";
            Directory.CreateDirectory(Path.GetFullPath(dir));
            string path = $"{dir}/{spec.Name}.shadersubgraph";
            File.WriteAllText(Path.GetFullPath(path), MultiJsonSerialize(graph));
            AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
            Debug.Log($"[SubGraphGen] wrote {path}");
        }

        // --- type mapping ---

        static AbstractShaderProperty MakeProperty(PortType type)
        {
            switch (type)
            {
                case PortType.Float: return new Vector1ShaderProperty();
                case PortType.Vector2: return new Vector2ShaderProperty();
                case PortType.Vector3: return new Vector3ShaderProperty();
                case PortType.Vector4: return new Vector4ShaderProperty();
                case PortType.Matrix4: return new Matrix4ShaderProperty();
                default: throw new Exception("unhandled port type " + type);
            }
        }

        static MaterialSlot MakeSlot(int id, Port p, SlotType slotType)
        {
            switch (p.Type)
            {
                case PortType.Float: return new Vector1MaterialSlot(id, p.Name, p.Name, slotType, 0f);
                case PortType.Vector2: return new Vector2MaterialSlot(id, p.Name, p.Name, slotType, Vector2.zero);
                case PortType.Vector3: return new Vector3MaterialSlot(id, p.Name, p.Name, slotType, Vector3.zero);
                case PortType.Vector4: return new Vector4MaterialSlot(id, p.Name, p.Name, slotType, Vector4.zero);
                case PortType.Matrix4: return new Matrix4MaterialSlot(id, p.Name, p.Name, slotType);
                default: throw new Exception("unhandled port type " + p.Type);
            }
        }

        // --- reflection helpers (internal API surface shifts between versions) ---

        static void AddGraphInput(GraphData graph, ShaderInput input)
        {
            var m = typeof(GraphData).GetMethod("AddGraphInput",
                        BindingFlags.Public | BindingFlags.Instance,
                        null, new[] { typeof(ShaderInput), typeof(int) }, null)
                    ?? typeof(GraphData).GetMethod("AddGraphInput",
                        BindingFlags.Public | BindingFlags.Instance,
                        null, new[] { typeof(ShaderInput) }, null);
            if (m == null) throw new Exception("GraphData.AddGraphInput not found");
            var args = m.GetParameters().Length == 2 ? new object[] { input, -1 } : new object[] { input };
            m.Invoke(graph, args);
        }

        static string MultiJsonSerialize(GraphData graph)
        {
            var t = Type.GetType("UnityEditor.ShaderGraph.Serialization.MultiJson, Unity.ShaderGraph.Editor")
                    ?? Type.GetType("UnityEditor.ShaderGraph.MultiJson, Unity.ShaderGraph.Editor");
            if (t == null) throw new Exception("MultiJson type not found");
            var m = t.GetMethod("Serialize", BindingFlags.Public | BindingFlags.Static);
            if (m == null) throw new Exception("MultiJson.Serialize not found");
            return (string)m.Invoke(null, new object[] { graph });
        }

        static void TryCall(object target, string method)
        {
            var m = target.GetType().GetMethod(method,
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance,
                null, Type.EmptyTypes, null);
            m?.Invoke(target, null);
        }

        // Sets a public member by name, falling back to a private backing field.
        static void SetMember(object target, string publicName, object value, string privateField = null)
        {
            var type = target.GetType();

            for (var t = type; t != null; t = t.BaseType)
            {
                var prop = t.GetProperty(publicName,
                    BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
                if (prop != null && prop.CanWrite)
                {
                    prop.SetValue(target, value);
                    return;
                }
                var field = t.GetField(publicName,
                    BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
                if (field != null)
                {
                    field.SetValue(target, value);
                    return;
                }
            }

            if (privateField != null)
            {
                for (var t = type; t != null; t = t.BaseType)
                {
                    var field = t.GetField(privateField,
                        BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
                    if (field != null)
                    {
                        field.SetValue(target, value);
                        return;
                    }
                }
            }

            throw new Exception($"could not set '{publicName}' on {type.Name}");
        }
    }
}
#endif
